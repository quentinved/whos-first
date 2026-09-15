# Who's First

Touch. Hold. Find out.

A finger picker and team maker for iPhone and iPad. Everyone holds one finger on the
screen; after a short countdown the app picks one or more of them, or splits the group into
two balanced teams. SwiftUI with a small UIKit adapter for multi-touch, iOS 17+, no
third-party dependencies, no ads, no purchases, no accounts. Game Center achievements are
the only optional network feature.

Shipped on the App Store as *Who's First: Finger Picker*. The Xcode project, scheme and
`FingrCore` package keep the original working name `Fingr`; renaming them would have been
a risk for no player-visible gain.

## Run

Open `Fingr.xcodeproj`, pick the **Fingr** scheme and any iPhone simulator, and run. The
options sheet has a **Try a round** button that plays a full round with virtual fingers,
so the game can be seen end to end with a mouse. Real multi-touch needs a device.

## How a round works

- Fingers land on the board and each gets a numbered, coloured ring. A countdown starts on
  its own once enough people have joined: one more than the number to keep, or two in
  team mode. Joining or lifting restarts it; moving a finger does not.
- The draw is uniform and without replacement. The spotlight that races between rings is
  decoration; the result is decided independently.
- Team mode splits everyone in two, with the larger team first when the count is odd.
- Results stay on screen after fingers lift. **Play again** or **Shuffle teams** resets.
- Six themes, a 3 or 5 second countdown, haptics, an original synthesised soundtrack, and a
  "quick dare" occasion that adds a challenge for whoever gets picked. Everything persists
  locally.
- Opening the options sheet or backgrounding the app cancels any running countdown, so a
  winner can never be picked while nobody is looking.

## Layout

```text
SwiftUI screens ──→ Application use cases ──→ Domain
UIKit input     ──→ GameSession               Round, Finger, TouchPoint
                    AppModel                  Preferences, Achievement
                        │
                        ▼ ports
                    PreferencesPort  ← UserDefaults
                    FeedbackPort     ← UIKit haptics / accessibility
                    SoundtrackPort   ← AVAudioPlayer + bundled cues
                    AchievementsPort ← GameKit (optional)
                    CountdownClock   ← cancellable system clock
                    RandomSource     ← system random generator
```

| Path | What lives there |
|---|---|
| `Packages/FingrCore` | Domain rules and application layer. Imports neither SwiftUI nor UIKit. |
| `Fingr/Composition` | Composition root; wires production adapters into the core. |
| `Fingr/Adapters` | UIKit touch surface, haptics, audio, UserDefaults, Game Center. |
| `Fingr/Presentation` | SwiftUI screens, components and themes. |
| `FingrUITests` | XCTest UI suite plus the App Store screenshot driver. |
| `Tools` | App Store Connect scripts: listing, screenshots, Game Center achievements. |
| `Server` | A two-page Cloudflare Worker for the privacy policy and support URLs. |
| `scripts` | Generators for the app icon, achievement badges and the soundtrack. |

`Round` holds the game rules and nothing else, so the draw, team balancing and player
limits are tested with a deterministic random source and no simulator. `GameSession`
drives the countdown with an injectable clock; the tests advance it by hand.

The touch adapter forwards each UIKit touch as a batched domain input with coordinates
normalised to the play area, so a finger keeps its identity and position through the
whole round. Game Center reporting is best effort: a player who never signs in gets the
same game, and the tally kept in `Preferences` is sent up whenever Game Center next
becomes reachable. Practice rounds never count.

## Verify

```sh
swift test --package-path Packages/FingrCore
xcodebuild -project Fingr.xcodeproj -scheme Fingr \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

The core suite covers exact winner counts, distinct selections, uniform team assignment,
balanced groups from two to ten players, chosen and automatic player counts, pausing for
options, cancellation, replay, music timing and preference migration. The UI suite covers
launch, the options sheet, demo and replay, persistence across relaunch, multiple winners,
a six-player team round, quick dares, full-screen touch coverage and real two-finger input
synthesised by XCTest. `ScreenshotTests` drives the six App Store marketing states.

## Assets

The icon and achievement badges are drawn by `scripts/generate-app-icon.swift` and
`scripts/generate-achievement-art.swift`. The three WAV cues in `Fingr/Resources/Audio`
are synthesised by `scripts/generate-soundtrack.py` with the Python standard library only.
The audio adapter uses the ambient session category so it respects Silent mode and mixes
with whatever else is playing; an interruption or unplugged headphones stops the cue
rather than resuming it later.

## Store tooling

`Tools/push-metadata.sh`, `Tools/push-screenshots.sh` and `Tools/seed-achievements.sh`
compile small Swift command-line tools against a shared App Store Connect client that
signs its own JWT with CryptoKit. They need an API key passed through the environment
and never submit anything for review. `AppStore/METADATA.md` records what has been pushed.
