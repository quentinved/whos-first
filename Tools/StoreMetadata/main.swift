import Foundation

// Pushes the App Store listing in copy.swift to App Store Connect: categories, names,
// descriptions, the age rating answers and what review needs to know.
//
// Nothing here submits the app for review, and nothing here touches screenshots — those go
// up with Tools/push-screenshots.sh.

let bundleID = CommandLine.arguments.dropFirst().first ?? "com.quentinvedrenne.whosfirst"
let app = ASC.app(bundleID: bundleID)
print("\(app.name) (\(bundleID))")

// MARK: The app record

let infos = ASC.many(ASC.call("GET", "/v1/apps/\(app.id)/appInfos"))
guard let info = infos.first(where: { ASC.attributes($0)["state"] as? String == "PREPARE_FOR_SUBMISSION" })
    ?? infos.first else { ASC.fail("no editable app info") }
let infoID = ASC.id(info)

// Entertainment rather than Games: this is the shelf the other finger pickers sit on, and
// it is a far smaller field to rank in.
_ = ASC.call("PATCH", "/v1/appInfos/\(infoID)", [
    "data": ["type": "appInfos", "id": infoID, "relationships": [
        "primaryCategory": ASC.link("appCategories", "ENTERTAINMENT"),
        "secondaryCategory": ASC.link("appCategories", "UTILITIES"),
    ]],
])
print("  categories: Entertainment / Utilities")

let infoLocalizations = ASC.many(ASC.call("GET", "/v1/appInfos/\(infoID)/appInfoLocalizations"))
for listing in listings {
    let fields: [String: Any] = ["name": listing.name, "subtitle": listing.subtitle,
                                 "privacyPolicyUrl": privacyURL]
    if let known = infoLocalizations.first(where: { ASC.attributes($0)["locale"] as? String == listing.locale }) {
        _ = ASC.call("PATCH", "/v1/appInfoLocalizations/\(ASC.id(known))", [
            "data": ["type": "appInfoLocalizations", "id": ASC.id(known), "attributes": fields],
        ])
        print("  \(listing.locale): name, subtitle and privacy policy updated")
    } else {
        var create = fields
        create["locale"] = listing.locale
        _ = ASC.call("POST", "/v1/appInfoLocalizations", [
            "data": ["type": "appInfoLocalizations", "attributes": create,
                     "relationships": ["appInfo": ASC.link("appInfos", infoID)]],
        ])
        print("  \(listing.locale): added")
    }
}

// MARK: The age rating

// Answered against what the app actually contains, which is eight pre-written dares, six
// colour themes and a countdown. Nothing is typed, shared, bought or wagered anywhere in it,
// so every one of these is a plain no.
let declaration: [String: Any] = [
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "gambling": false,
    "gunsOrOtherWeapons": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    // The dares are a fixed list written into the app. Nobody can type anything, and there
    // is nowhere for it to go if they could.
    "messagingAndChat": false,
    "userGeneratedContent": false,
    "unrestrictedWebAccess": false,
    "lootBox": false,
    "advertising": false,
    "healthOrWellnessTopics": false,
    // Nothing to gate: no purchases, no ads, no chat, no web.
    "parentalControls": false,
    "ageAssurance": false,
]
_ = ASC.call("PATCH", "/v1/ageRatingDeclarations/\(infoID)", [
    "data": ["type": "ageRatingDeclarations", "id": infoID, "attributes": declaration],
])
let rated = ASC.attributes(ASC.one(ASC.call("GET", "/v1/appInfos/\(infoID)")))
print("  age rating: \(rated["appStoreAgeRating"] as? String ?? "not computed yet")")

// MARK: The version

let versions = ASC.many(ASC.call("GET", "/v1/apps/\(app.id)/appStoreVersions"))
guard let version = versions.first(where: { ASC.attributes($0)["appStoreState"] as? String == "PREPARE_FOR_SUBMISSION" })
    ?? versions.first else { ASC.fail("no editable version") }
let versionID = ASC.id(version)

_ = ASC.call("PATCH", "/v1/appStoreVersions/\(versionID)", [
    "data": ["type": "appStoreVersions", "id": versionID,
             "attributes": ["copyright": "2026 Quentin Vedrenne",
                            "releaseType": "AFTER_APPROVAL"]],
])
print("  copyright and release type set")

let versionLocalizations = ASC.many(ASC.call("GET", "/v1/appStoreVersions/\(versionID)/appStoreVersionLocalizations"))
for listing in listings {
    // whatsNew is deliberately left out: a first version does not show it, and sending one
    // is rejected.
    let fields: [String: Any] = [
        "description": listing.description,
        "keywords": listing.keywords,
        "promotionalText": listing.promotional,
        "supportUrl": supportURL,
    ]
    if let known = versionLocalizations.first(where: { ASC.attributes($0)["locale"] as? String == listing.locale }) {
        _ = ASC.call("PATCH", "/v1/appStoreVersionLocalizations/\(ASC.id(known))", [
            "data": ["type": "appStoreVersionLocalizations", "id": ASC.id(known), "attributes": fields],
        ])
        print("  \(listing.locale): description, keywords and support URL updated")
    } else {
        var create = fields
        create["locale"] = listing.locale
        _ = ASC.call("POST", "/v1/appStoreVersionLocalizations", [
            "data": ["type": "appStoreVersionLocalizations", "attributes": create,
                     "relationships": ["appStoreVersion": ASC.link("appStoreVersions", versionID)]],
        ])
        print("  \(listing.locale): added")
    }
}

// MARK: What review needs to know

let existingDetail = ASC.one(ASC.call("GET", "/v1/appStoreVersions/\(versionID)/appStoreReviewDetail"))
var contact: [String: Any] = [
    "contactFirstName": "Quentin",
    "contactLastName": "Vedrenne",
    "contactEmail": "contact@quentinvedrenne.com",
    "demoAccountRequired": false,
    "notes": reviewNotes,
]
if let phone = ASC.environment["WHOSFIRST_CONTACT_PHONE"] { contact["contactPhone"] = phone }

if ASC.id(existingDetail).isEmpty {
    _ = ASC.call("POST", "/v1/appStoreReviewDetails", [
        "data": ["type": "appStoreReviewDetails", "attributes": contact,
                 "relationships": ["appStoreVersion": ASC.link("appStoreVersions", versionID)]],
    ])
    print("  review notes: added")
} else {
    _ = ASC.call("PATCH", "/v1/appStoreReviewDetails/\(ASC.id(existingDetail))", [
        "data": ["type": "appStoreReviewDetails", "id": ASC.id(existingDetail), "attributes": contact],
    ])
    print("  review notes: updated")
}

print("done — \(listings.count) language(s)")
