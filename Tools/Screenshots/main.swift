import Foundation
import CryptoKit

// Uploads the App Store screenshots from AppStore/screenshots to App Store Connect.
//
//   ASC_KEY=/path/to/AuthKey.p8 ASC_KEY_ID=XXXXXXXXXX ASC_ISSUER_ID=xxxx-xxxx \
//       Tools/push-screenshots.sh
//
// Re-running is safe: a set that already holds screenshots is emptied first, so the order
// on the listing always matches the order of the files on disk. Nothing here submits the
// app for review.

/// One folder of numbered PNGs, and the display type App Store Connect files them under.
struct ScreenshotSet {
    let folder: String
    let displayType: String
}

let sets = [
    ScreenshotSet(folder: "iphone-6.9", displayType: "APP_IPHONE_67"),
    ScreenshotSet(folder: "ipad-13", displayType: "APP_IPAD_PRO_3GEN_129"),
]

let root = CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
let locale = ASC.environment["ASC_LOCALE"] ?? "en-US"

let app = ASC.app(bundleID: ASC.environment["ASC_BUNDLE_ID"] ?? "com.quentinvedrenne.whosfirst")
print("app: \(app.name)")

guard let version = ASC.many(ASC.call("GET", "/v1/apps/\(app.id)/appStoreVersions?limit=1")).first else {
    ASC.fail("no App Store version to attach screenshots to")
}
let versionID = ASC.id(version)

let localizations = ASC.many(ASC.call("GET", "/v1/appStoreVersions/\(versionID)/appStoreVersionLocalizations?limit=50"))
guard let localization = localizations.first(where: { ASC.attributes($0)["locale"] as? String == locale }) else {
    ASC.fail("no \(locale) localization on version \(versionID)")
}
let localizationID = ASC.id(localization)

for set in sets {
    let folder = URL(fileURLWithPath: root).appendingPathComponent("AppStore/screenshots/\(set.folder)")
    let files = ((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [])
        .filter { $0.hasSuffix(".png") }
        .sorted()
    guard !files.isEmpty else {
        print("\(set.folder): nothing to upload, skipping")
        continue
    }

    // Reuse the set if it is already there; App Store Connect allows only one per type.
    let existing = ASC.many(ASC.call("GET", "/v1/appStoreVersionLocalizations/\(localizationID)/appScreenshotSets?limit=50"))
    let match = existing.first { ASC.attributes($0)["screenshotDisplayType"] as? String == set.displayType }
    let setID: String
    if let match {
        setID = ASC.id(match)
        // Clear it out, so a re-run cannot leave last time's order interleaved with this one.
        for old in ASC.many(ASC.call("GET", "/v1/appScreenshotSets/\(setID)/appScreenshots?limit=50")) {
            _ = ASC.call("DELETE", "/v1/appScreenshots/\(ASC.id(old))")
        }
        print("\(set.displayType): reusing set \(setID), cleared")
    } else {
        let created = ASC.call("POST", "/v1/appScreenshotSets", [
            "data": [
                "type": "appScreenshotSets",
                "attributes": ["screenshotDisplayType": set.displayType],
                "relationships": [
                    "appStoreVersionLocalization": ASC.link("appStoreVersionLocalizations", localizationID),
                ],
            ],
        ])
        setID = ASC.id(ASC.one(created))
        print("\(set.displayType): created set \(setID)")
    }

    for name in files {
        let data = try! Data(contentsOf: folder.appendingPathComponent(name))

        // 1. Reserve the slot. App Store Connect answers with where to put the bytes.
        let reserved = ASC.one(ASC.call("POST", "/v1/appScreenshots", [
            "data": [
                "type": "appScreenshots",
                "attributes": ["fileSize": data.count, "fileName": name],
                "relationships": ["appScreenshotSet": ASC.link("appScreenshotSets", setID)],
            ],
        ]))
        let screenshotID = ASC.id(reserved)
        let operations = ASC.attributes(reserved)["uploadOperations"] as? [[String: Any]] ?? []
        guard !operations.isEmpty else { ASC.fail("\(name): no upload operations came back") }

        // 2. Send the bytes straight to object storage, without the bearer token.
        for operation in operations {
            guard let urlString = operation["url"] as? String, let url = URL(string: urlString),
                  let method = operation["method"] as? String,
                  let offset = operation["offset"] as? Int, let length = operation["length"] as? Int else {
                ASC.fail("\(name): malformed upload operation")
            }
            var request = URLRequest(url: url)
            request.httpMethod = method
            for header in operation["requestHeaders"] as? [[String: Any]] ?? [] {
                if let field = header["name"] as? String, let value = header["value"] as? String {
                    request.setValue(value, forHTTPHeaderField: field)
                }
            }
            request.httpBody = data.subdata(in: offset ..< (offset + length))
            let (status, body) = ASC.send(request)
            guard (200 ..< 300).contains(status) else {
                ASC.fail("\(name): upload chunk failed with HTTP \(status): \(String(decoding: body, as: UTF8.self))")
            }
        }

        // 3. Commit. The checksum is how Apple knows the bytes arrived intact.
        let checksum = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        _ = ASC.call("PATCH", "/v1/appScreenshots/\(screenshotID)", [
            "data": [
                "type": "appScreenshots",
                "id": screenshotID,
                "attributes": ["uploaded": true, "sourceFileChecksum": checksum],
            ],
        ])
        print("  uploaded \(name) (\(data.count) bytes)")
    }
}

print("done")
