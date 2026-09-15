import Foundation

// The App Store listing, in one place. push-metadata.sh sends this to App Store Connect, so
// this file is the source of truth rather than the web form.
//
// Keep it true. Everything claimed here is a claim about the app, and reviewers check.

let privacyURL = "https://whos-first.quentin-vedrenne.workers.dev/privacy"
let supportURL = ASC.environment["WHOSFIRST_SUPPORT_URL"]
    ?? "https://whos-first.quentin-vedrenne.workers.dev/support"

/// One language's listing. App Store Connect caps name and subtitle at 30 characters,
/// keywords at 100 and promotional text at 170.
struct Listing {
    let locale: String
    let name: String
    let subtitle: String
    let keywords: String
    let promotional: String
    let description: String
}

let listings = [
    Listing(
        locale: "en-US",
        name: "Who's First: Finger Picker",
        subtitle: "Who pays? Random team maker",
        // Never repeat a word that is already in the name or the subtitle: App Store Connect
        // searches all three fields together, so a repeat is a wasted character.
        keywords: "chooser,decision,select,party,group,friends,split,generator,turn,order,dare,choose,lot,wheel,pick",
        promotional: "Someone has to go first. Everyone holds a finger, the app picks one - or splits you into two balanced teams. No accounts, no ads. Touch, hold, find out.",
        description: """
        Someone has to go first. Let the app decide.

        Everyone puts a finger on the screen. Hold still for three seconds. One finger lights up - and that's your answer. No arguing, no rock-paper-scissors, no "you go", "no, you go".

        WHAT IT SETTLES
        - Who pays for dinner
        - Who goes first
        - Who picks the movie
        - Who's on aux
        - Who makes the coffee
        - Who's doing the dishes

        TWO WAYS TO PLAY
        Pick - Choose one person at random, or up to nine people at once.
        Teams - Split everyone into two balanced teams instantly. Six players become 3 vs 3. Five become 3 vs 2. Nobody picks last.

        BUILT FOR THE MOMENT
        - Up to 10 fingers at once
        - A 3 or 5 second countdown with an original suspense soundtrack
        - Every finger gets its own glowing ring and number
        - Add a quick dare for whoever gets picked
        - Six free themes, dark and light
        - Play again or shuffle teams in a single tap
        - Works on iPhone and iPad

        EIGHT ACHIEVEMENTS
        Game Center achievements for rounds you actually play: your first call, ten rounds, fifty, two hundred and fifty, your first team split, ten fingers on the screen at once, ten challenges handed out, and a round in every theme. Signing in is optional, and practice rounds never count.

        GENUINELY RANDOM
        Every finger has exactly the same chance, every single round. The spotlight that races between fingers during the countdown is pure suspense - the actual draw is independent and uniform. Teams are properly shuffled and always balanced.

        NOTHING IN THE WAY
        - No account and no sign-up
        - The game works offline; only Game Center achievements need a connection
        - No ads
        - No in-app purchases
        - We collect no data about you, ever

        Playing alone? Open the options and tap "Try a round" to watch a full round with virtual players.

        Touch. Hold. Find out.
        """
    ),
]

/// What App Store review is told, and what App Store Connect keeps in the Notes field of
/// App Review Information. Written for somebody who has never seen the app and has one
/// device: without this, a reviewer holds one finger, nothing happens, and the app looks
/// broken. It also answers, up front, the questions review asks every new developer -
/// accounts, purchases, user content, external services, regions and rights - because
/// silence on any of them is what triggers an information request.
let reviewNotes = """
WHAT THIS APP IS

Who's First is a multi-touch group decision maker for iPhone and iPad. Two or more people \
each hold one finger on the screen; after a short countdown the app randomly picks one of \
them, or splits everyone into two balanced teams. It settles who pays, who goes first, who \
is on aux. The audience is general - friends, families and colleagues in the same room, \
rated 4+.

HOW TO TEST THIS APP WITHOUT A SECOND PERSON

This app is driven by multi-touch. With only one finger on the screen the countdown \
intentionally does not start and the board reads "Keep holding. Waiting for another \
player" - that is correct behaviour, not a bug.

To see a complete round on your own:
1. Launch the app.
2. Tap the options button (the sliders icon) in the top-right corner.
3. Scroll to the bottom of the sheet and tap "Try a round".
4. The app runs a full countdown and reveal using virtual players.

To test real multi-touch, place two fingers on the screen at the same time (thumb and index \
finger works well) and hold them still for three seconds. A countdown starts and one of the \
two fingers is selected.

To test team mode: options sheet > "Teams" > "Try a round". Everyone on the screen is split \
into two balanced teams.

NO LOGIN, NO PURCHASES, NO USER CONTENT

- No account, sign-in or demo credentials are required or possible. There is nothing to \
register, log into or delete, so no account deletion flow applies.
- No in-app purchases and no subscriptions. Every feature, including all six themes, is \
free and available on first launch.
- No user-generated content, so no reporting or blocking mechanism is required. Players \
cannot type, upload or share anything: the app contains no text input of any kind. The \
eight "quick dare" prompts are fixed text we wrote, shipped in the binary.

EXTERNAL SERVICES

Game Center (Apple) is the only external service and the app's only network use. Signing in \
is optional and the app never blocks on it: declining the prompt, or having no network, \
leaves the game working identically. Progress is kept on the device and reported later if \
the player ever signs in. There are eight achievements, all earned by playing real rounds - \
practice rounds ("Try a round") never count.

There is nothing else: no third-party SDKs, no analytics, no advertising, no authentication \
provider, no payment processor, no AI service, and no back end of ours. The app makes no \
other network requests. The privacy policy and support pages are static web pages we host; \
the app itself never contacts them.

REGIONS

The app behaves identically in every region. One English build, the same features and \
content everywhere, no geo-gating and no region-specific behaviour, and the game runs fully \
offline. Only Game Center availability is Apple's own.

RIGHTS AND THIRD-PARTY MATERIAL

Not a regulated industry, and no protected third-party material. Everything is original and \
produced by scripts inside this project: the app icon, the achievement badge artwork and \
the three audio cues. Interface glyphs are Apple's SF Symbols, used within the app. The \
dare prompts are our own writing.

OTHER NOTES

- We collect no data. The bundled privacy manifest declares no tracking and no collected \
data.
- iPhone is intentionally locked to portrait so the board cannot rotate out from under \
fingers that are being held still. iPad supports all orientations.

Privacy policy: \(privacyURL)
"""
