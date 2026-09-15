import Foundation

// Seeds the Game Center achievements in App Store Connect from the Achievement enum, so the
// app and the store can never drift apart. The core sources are compiled straight into this
// tool by seed-achievements.sh, which is why there is no import of FingrCore here.
//
//   ASC_KEY=/path/to/AuthKey.p8 ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxx-xxxx \
//       Tools/seed-achievements.sh
//
// Re-running is safe: existing achievements are updated in place and finished artwork is
// left alone. Nothing here submits the app for review.

let arguments = CommandLine.arguments
guard arguments.count == 3 else { ASC.fail("usage: seed-achievements <bundle id> <artwork directory>") }
let bundleID = arguments[1]
let artwork = URL(fileURLWithPath: arguments[2], isDirectory: true)
let locale = "en-US"

let app = ASC.app(bundleID: bundleID)
print("\(app.name) (\(bundleID))")

// Turning Game Center on for the app is a record of its own, separate from the capability
// on the App ID. A first run creates it.
var detailID = ASC.id(ASC.one(ASC.call("GET", "/v1/apps/\(app.id)/gameCenterDetail")))
if detailID.isEmpty {
    let made = ASC.one(ASC.call("POST", "/v1/gameCenterDetails", [
        "data": ["type": "gameCenterDetails",
                 "relationships": ["app": ASC.link("apps", app.id)]],
    ]))
    detailID = ASC.id(made)
    guard !detailID.isEmpty else { ASC.fail("could not enable Game Center for this app") }
    print("  Game Center enabled for the app")
}

/// vendorIdentifier → achievement id, so a second run updates rather than duplicates.
var existing: [String: String] = [:]
for achievement in ASC.many(ASC.call("GET", "/v1/gameCenterDetails/\(detailID)/gameCenterAchievements?limit=200")) {
    if let vendor = ASC.attributes(achievement)["vendorIdentifier"] as? String {
        existing[vendor] = ASC.id(achievement)
    }
}

for badge in Achievement.allCases.sorted(by: { $0.displayOrder < $1.displayOrder }) {
    let picture = artwork.appendingPathComponent("\(badge.rawValue).png")
    guard let bytes = try? Data(contentsOf: picture) else { ASC.fail("no artwork at \(picture.path)") }

    // "Hidden: No" in the web form is showBeforeEarned: true. None of these are secrets —
    // seeing what is left to do is the point.
    let settings: [String: Any] = [
        "referenceName": badge.referenceName,
        "points": badge.points,
        "showBeforeEarned": true,
        "repeatable": false,
    ]
    let achievementID: String
    if let known = existing[badge.rawValue] {
        achievementID = known
        _ = ASC.call("PATCH", "/v1/gameCenterAchievements/\(known)",
                     ["data": ["type": "gameCenterAchievements", "id": known, "attributes": settings]])
        print("  \(badge.rawValue): updated")
    } else {
        var create = settings
        create["vendorIdentifier"] = badge.rawValue
        let made = ASC.one(ASC.call("POST", "/v1/gameCenterAchievements", [
            "data": ["type": "gameCenterAchievements", "attributes": create,
                     "relationships": ["gameCenterDetail": ASC.link("gameCenterDetails", detailID)]],
        ]))
        achievementID = ASC.id(made)
        print("  \(badge.rawValue): created")
    }

    // Localizations hang off a version rather than the achievement: the editable one is
    // whichever version is still being prepared.
    let versions = ASC.many(ASC.call("GET", "/v2/gameCenterAchievements/\(achievementID)/versions"))
    guard let version = versions.first(where: { ASC.attributes($0)["state"] as? String == "PREPARE_FOR_SUBMISSION" })
        ?? versions.last else { ASC.fail("\(badge.rawValue) has no editable version") }
    let versionID = ASC.id(version)

    let text: [String: Any] = [
        "locale": locale,
        "name": badge.title,
        "beforeEarnedDescription": badge.unearnedDescription,
        "afterEarnedDescription": badge.earnedDescription,
    ]
    let localizations = ASC.many(ASC.call("GET", "/v2/gameCenterAchievementVersions/\(versionID)/localizations"))
    let localizationID: String
    if let known = localizations.first(where: { ASC.attributes($0)["locale"] as? String == locale }) {
        localizationID = ASC.id(known)
        // `locale` is fixed at creation, so an update sends only the words.
        var revision = text
        revision["locale"] = nil
        _ = ASC.call("PATCH", "/v2/gameCenterAchievementLocalizations/\(localizationID)",
                     ["data": ["type": "gameCenterAchievementLocalizations", "id": localizationID,
                               "attributes": revision.compactMapValues { $0 }]])
    } else {
        let made = ASC.one(ASC.call("POST", "/v2/gameCenterAchievementLocalizations", [
            "data": ["type": "gameCenterAchievementLocalizations", "attributes": text,
                     "relationships": ["version": ASC.link("gameCenterAchievementVersions", versionID)]],
        ]))
        localizationID = ASC.id(made)
    }

    // Artwork. An image that never finished uploading is dropped and sent again rather than
    // left to sit there, since App Store Connect will not accept the localization without a
    // complete one.
    let current = ASC.one(ASC.call("GET", "/v2/gameCenterAchievementLocalizations/\(localizationID)/image"))
    if !ASC.id(current).isEmpty {
        let state = (ASC.attributes(current)["assetDeliveryState"] as? [String: Any])?["state"] as? String
        if state == "COMPLETE" {
            print("    artwork already uploaded")
            continue
        }
        _ = ASC.call("DELETE", "/v1/gameCenterAchievementImages/\(ASC.id(current))")
    }

    let reservation = ASC.one(ASC.call("POST", "/v1/gameCenterAchievementImages", [
        "data": ["type": "gameCenterAchievementImages",
                 "attributes": ["fileSize": bytes.count, "fileName": "\(badge.rawValue).png"],
                 "relationships": ["gameCenterAchievementLocalization":
                                    ASC.link("gameCenterAchievementLocalizations", localizationID)]],
    ]))
    let imageID = ASC.id(reservation)
    for operation in ASC.attributes(reservation)["uploadOperations"] as? [[String: Any]] ?? [] {
        guard let address = operation["url"] as? String, let url = URL(string: address),
              let offset = operation["offset"] as? Int, let length = operation["length"] as? Int else {
            ASC.fail("\(badge.rawValue): malformed upload operation")
        }
        var upload = URLRequest(url: url)
        upload.httpMethod = operation["method"] as? String ?? "PUT"
        for header in operation["requestHeaders"] as? [[String: Any]] ?? [] {
            if let name = header["name"] as? String, let value = header["value"] as? String {
                upload.setValue(value, forHTTPHeaderField: name)
            }
        }
        upload.httpBody = bytes.subdata(in: offset ..< (offset + length))
        let (status, _) = ASC.send(upload)
        guard (200 ..< 300).contains(status) else {
            ASC.fail("\(badge.rawValue): upload returned HTTP \(status)")
        }
    }
    _ = ASC.call("PATCH", "/v1/gameCenterAchievementImages/\(imageID)",
                 ["data": ["type": "gameCenterAchievementImages", "id": imageID,
                           "attributes": ["uploaded": true]]])
    print("    artwork uploaded (\(bytes.count) bytes)")
}

let points = Achievement.allCases.reduce(0) { $0 + $1.points }
print("done — \(Achievement.allCases.count) achievements, \(points) points")
