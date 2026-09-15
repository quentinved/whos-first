# Who's First — App Store submission

The listing is **not** maintained in this file any more. It lives in
[`Tools/StoreMetadata/copy.swift`](../Tools/StoreMetadata/copy.swift) and is pushed to App
Store Connect with `Tools/push-metadata.sh`, so the repo is the source of truth and the web
form is only ever the output.

App: **Who's First: Finger Picker** · `com.quentinvedrenne.whosfirst` · Apple ID `6811686319`

---

## Pushed and verified

| Field | Value | Where it comes from |
|---|---|---|
| Name | `Who's First: Finger Picker` | `copy.swift` |
| Subtitle | `Who pays? Random team maker` | `copy.swift` |
| Keywords (97/100) | `chooser,decision,select,…` | `copy.swift` |
| Description (1759 chars) | — | `copy.swift` |
| Promotional text | — | `copy.swift` |
| Primary category | Entertainment | `StoreMetadata/main.swift` |
| Secondary category | Utilities | `StoreMetadata/main.swift` |
| Age rating | **4+** (every answer None/No) | `StoreMetadata/main.swift` |
| Copyright | `2026 Quentin Vedrenne` | `StoreMetadata/main.swift` |
| Release | After approval | `StoreMetadata/main.swift` |
| Privacy Policy URL | https://whos-first.quentin-vedrenne.workers.dev/privacy | `Server/` |
| Support URL | https://whos-first.quentin-vedrenne.workers.dev/support | `Server/` |
| Screenshots | 6 × iPhone 6.9", 6 × iPad 13", all COMPLETE | `Tools/push-screenshots.sh` |
| Game Center | enabled, 8 achievements, 290 points, artwork uploaded | `Tools/seed-achievements.sh` |

## Still to do

- [ ] **Review contact phone.** Apple rejects the review details without one, in
      `+<country code> <number>` form. Then:
      `WHOSFIRST_CONTACT_PHONE='+33 …' Tools/push-metadata.sh`
      That one call also posts the review notes, which are the most important field in the
      submission — see below.
- [ ] Archive in Xcode (Any iOS Device, Release), upload, attach the build to 1.0.
- [ ] Submit for review. None of the tooling here submits anything.

---

## The three commands

All three need the App Store Connect API key, and none of them submit the app:

```sh
export ASC_KEY=/path/to/AuthKey.p8
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Tools/push-metadata.sh        # listing, categories, age rating, review notes
Tools/push-screenshots.sh     # AppStore/screenshots → the listing
Tools/seed-achievements.sh    # Game Center achievements + artwork
```

Re-running any of them is safe. The key is a credential and lives outside the repo.

---

## App Privacy  (ASC ▸ App Privacy — the one part still done by hand)

**Do you or your third-party partners collect data from this app?** → **No**

That single answer completes the section, and it is accurate. We run no server and the app
sends us nothing. Game Center is Apple's own service: a signed-in player's achievement
progress goes to Apple, under Apple's privacy policy, and none of it reaches us.

A matching privacy manifest ships in the binary at `Fingr/PrivacyInfo.xcprivacy`, declaring
no tracking, no collected data, and `CA92.1` as the required reason for UserDefaults. That
prevents the "ITMS-91053: Missing API declaration" warning email after upload.

## Export Compliance

**Does your app use encryption?** → **No.** `ITSAppUsesNonExemptEncryption = NO` is already
in the build settings, so App Store Connect stops asking on every upload.

---

## Screenshots

`AppStore/screenshots/iphone-6.9` (1320 × 2868) and `AppStore/screenshots/ipad-13`
(2064 × 2752), captured from the real app by `FingrUITests/ScreenshotTests.swift` — not
mockups, so they cannot drift from the product. Numbered in upload order:

1. **Countdown** — six fingers held, clock running. The fullest frame in the app.
2. **Winner** — the payoff: one finger chosen, everyone else gone.
3. **Teams** — 3 vs 3 with the team summary.
4. **Dare** — the feature that makes people keep the app.
5. **Options** — every setting in one sheet.
6. **Light theme** — proves it is not only a dark app.

Shots 1–4 are captured through the built-in practice round, because a simulator cannot
produce six real fingers; that is why their footer reads "Practice round · End". It is
genuine, unretouched app UI. To regenerate:

```sh
xcodebuild -project Fingr.xcodeproj -scheme Fingr \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:FingrUITests/ScreenshotTests \
  -resultBundlePath /tmp/shots.xcresult \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test

xcrun xcresulttool export attachments --path /tmp/shots.xcresult --output-path /tmp/shots
```

App Store Connect copies the 6.9" set down to smaller iPhones automatically.

---

## Game Center

Eight achievements, 290 of Apple's 1000 points, defined once in
[`Achievement.swift`](../Packages/FingrCore/Sources/FingrCore/Domain/Achievement.swift) and
seeded from that same enum, so the app and the store cannot disagree.

| Identifier | Title | Earned by | Points |
|---|---|---|---|
| `first.call` | First Call | your first real round | 5 |
| `rounds.10` | Regulars | 10 rounds | 25 |
| `rounds.50` | House Rules | 50 rounds | 50 |
| `rounds.250` | Settled It | 250 rounds | 100 |
| `teams.first` | Pick Sides | one team round | 10 |
| `table.ten` | Full House | ten fingers at once | 50 |
| `dare.ten` | Dare Devil | 10 dare rounds | 25 |
| `themes.all` | Interior Decorator | a round in all six themes | 25 |

Signing in is optional and never blocks play: progress is tallied locally and reported the
next time Game Center is reachable. Practice rounds never count. The identifiers are what
Game Center keys a player's progress on, so they must not change once shipped.

Badge artwork is generated, not hand-drawn — `swift scripts/generate-achievement-art.swift`
writes `Artwork/Achievements/*.png` at 512 × 512 with no alpha, which is what App Store
Connect accepts.

---

## The two hosted pages

`Server/` is a Cloudflare Worker serving nothing but the privacy policy and the support page,
French first with English below — the same shape as the Scopa ladder's, minus the ladder.
Deploy with `cd Server && npx wrangler deploy`. Both URLs are mandatory for submission, and
both are live.
