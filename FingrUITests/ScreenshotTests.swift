import XCTest

/// Drives the app into each App Store marketing state and attaches a full-screen,
/// native-resolution screenshot. Export with:
///   xcrun xcresulttool export attachments --path <result bundle> --output-path <dir>
@MainActor
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-ui-state"]
        app.launch()
        XCTAssertTrue(app.otherElements["game.touchSurface"].waitForExistence(timeout: 10))
        return app
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Sheet presentation occasionally drops the first tap on a cold simulator,
    /// so give it a second attempt before failing the capture.
    private func openOptions(_ app: XCUIApplication) {
        let done = app.buttons["settings.done"]
        for attempt in 0..<3 {
            if done.waitForExistence(timeout: attempt == 0 ? 0.5 : 8) { return }
            let menu = app.buttons["game.menu"]
            XCTAssertTrue(menu.waitForExistence(timeout: 10))
            menu.tap()
        }
        XCTAssertTrue(done.waitForExistence(timeout: 10), "Options sheet never appeared")
    }

    /// Scroll the options sheet itself, never the whole application. On iPad the
    /// sheet is a form sheet, so an app-level swipe lands outside it, backgrounds
    /// the app, and the deactivation cancels the round we are about to capture.
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.isHittable { return }
            let sheet = app.scrollViews.firstMatch
            if sheet.exists { sheet.swipeUp() } else { app.swipeUp() }
        }
    }

    /// Tap a chip and confirm it really took. Switching game mode reflows the
    /// sheet, so a tap issued immediately afterwards can land on stale geometry
    /// and silently miss — which then shows up as the wrong player count in the
    /// captured screenshot rather than as a test failure.
    private func select(_ identifier: String, in app: XCUIApplication) {
        let element = app.buttons[identifier]
        for _ in 0..<3 {
            reveal(element, in: app)
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(identifier) never appeared")
            element.tap()
            let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isSelected == true"), object: element)
            if XCTWaiter.wait(for: [selected], timeout: 3) == .completed { return }
        }
        XCTFail("\(identifier) never became selected")
    }

    private func startDemo(_ app: XCUIApplication) {
        reveal(app.buttons["settings.demo"], in: app)
        app.buttons["settings.demo"].tap()
    }

    /// Lead shot: six fingers held, clock running. Captured at "3" rather than on
    /// the first frame, so every orb has finished its entrance animation.
    func test01Countdown() {
        let app = launch()
        openOptions(app)
        select("settings.players.6", in: app)
        select("settings.countdown.5", in: app)
        startDemo(app)
        let countdown = app.staticTexts["game.countdown"]
        XCTAssertTrue(countdown.waitForExistence(timeout: 20))
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3"), object: countdown)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 8), .completed, "Countdown never reached 3")
        shot("01-Countdown")
    }

    /// The payoff: one player picked out of six.
    func test02Winner() {
        let app = launch()
        openOptions(app)
        select("settings.players.6", in: app)
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.winner"].waitForExistence(timeout: 20))
        shot("02-Winner")
    }

    /// Team mode: six players split three versus three.
    func test03Teams() {
        let app = launch()
        openOptions(app)
        select("settings.mode.teams", in: app)
        select("settings.players.6", in: app)
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.teamsResult"].waitForExistence(timeout: 20))
        shot("03-Teams")
    }

    /// Quick dare: the picked player gets a challenge.
    func test04Dare() {
        let app = launch()
        openOptions(app)
        select("settings.players.4", in: app)
        select("settings.prompt.tinyDare", in: app)
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.dare"].waitForExistence(timeout: 15))
        shot("04-Dare")
    }

    /// Everything is one sheet: modes, players, occasions, themes, sound.
    func test05Options() {
        let app = launch()
        openOptions(app)
        reveal(app.buttons["theme.afterHours"], in: app)
        shot("05-Options")
    }

    /// Six free themes, shown on the ready board in a light palette.
    func test06LightTheme() {
        let app = launch()
        openOptions(app)
        select("theme.daydream", in: app)
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.staticTexts["game.question"].waitForExistence(timeout: 5))
        shot("06-Light-theme")
    }
}
