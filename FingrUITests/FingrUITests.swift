import XCTest

@MainActor
final class FingrUITests: XCTestCase {
    private func launch(reset: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + (reset ? ["-reset-ui-state"] : [])
        app.launch()
        return app
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func openOptions(_ app: XCUIApplication) {
        app.buttons["game.menu"].tap()
        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 3))
    }

    private func startDemo(_ app: XCUIApplication) {
        openOptions(app)
        reveal(app.buttons["settings.demo"], in: app)
        app.buttons["settings.demo"].tap()
    }

    func testLaunchIsImmediatelyPlayableAndDemoCanReplay() {
        let app = launch()
        let surface = app.otherElements["game.touchSurface"]
        XCTAssertTrue(surface.waitForExistence(timeout: 5))
        XCTAssertTrue(surface.isHittable)
        expectLabel(app.staticTexts["game.selectionRule"], "Keep 1 · 2+ players")
        let readyBoard = surface.frame
        XCTAssertEqual(readyBoard.minX, app.frame.minX, accuracy: 1)
        XCTAssertEqual(readyBoard.minY, app.frame.minY, accuracy: 1)
        XCTAssertEqual(readyBoard.width, app.frame.width, accuracy: 1)
        XCTAssertEqual(readyBoard.height, app.frame.height, accuracy: 1,
                       "The play surface must fill the screen, including safe areas")
        capture("01-Ready-on-launch")
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.winner"].waitForExistence(timeout: 10))
        XCTAssertEqual(surface.frame, readyBoard, "The reveal must keep fingers at their original screen positions")
        capture("02-Demo-winner")
        app.buttons["game.again"].tap()
        expectLabel(app.staticTexts["game.status"], "Waiting for players")
        XCTAssertTrue(surface.isHittable)
    }

    func testThemesAndPreferencesPersistAfterRelaunch() {
        var app = launch()
        openOptions(app)
        reveal(app.buttons["theme.afterHours"], in: app)
        XCTAssertTrue(app.buttons["theme.afterHours"].isSelected, "After Hours is the default")
        app.buttons["theme.daydream"].tap()
        XCTAssertTrue(app.buttons["theme.daydream"].isSelected)
        capture("03-One-menu")
        reveal(app.buttons["settings.countdown.5"], in: app)
        app.buttons["settings.countdown.5"].tap()
        reveal(app.switches["settings.sound"], in: app)
        XCTAssertEqual(app.switches["settings.sound"].value as? String, "1")
        app.switches["settings.sound"].tap()
        app.buttons["settings.done"].tap()
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.otherElements["game.touchSurface"].waitForExistence(timeout: 5))
        openOptions(app)
        reveal(app.buttons["theme.daydream"], in: app)
        XCTAssertTrue(app.buttons["theme.daydream"].isSelected)
        reveal(app.buttons["settings.countdown.5"], in: app)
        XCTAssertTrue(app.buttons["settings.countdown.5"].isSelected)
        reveal(app.switches["settings.sound"], in: app)
        XCTAssertEqual(app.switches["settings.sound"].value as? String, "0")
    }

    func testRealMultitouchNeedsTwoFingers() {
        let app = launch()
        let surface = app.otherElements["game.touchSurface"]
        XCTAssertTrue(surface.waitForExistence(timeout: 5))
        surface.press(forDuration: 3.5)
        XCTAssertFalse(app.staticTexts["game.winner"].exists, "One finger cannot win")
        surface.pinch(withScale: 2, velocity: 0.15)
        XCTAssertTrue(app.staticTexts["game.winner"].waitForExistence(timeout: 5))
        capture("04-Multitouch-winner")
        app.buttons["game.again"].tap()
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["game.status"].waitForExistence(timeout: 3))
        expectLabel(app.staticTexts["game.status"], "Waiting for players")
    }

    func testMultipleWinnersAndSavedCount() {
        var app = launch()
        openOptions(app)
        expectLabel(app.staticTexts["settings.winnerCount.value"], "Keep 1 · Needs 2+ players")
        app.buttons["settings.winnerCount.2"].tap()
        app.buttons["settings.done"].tap()
        expectLabel(app.staticTexts["game.selectionRule"], "Keep 2 · 3+ players")
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.winner"].waitForExistence(timeout: 10))
        expectLabel(app.staticTexts["game.winner"], "2 selected")
        let selectedCount = app.descendants(matching: .any).matching(identifier: "game.selectedCount").firstMatch
        XCTAssertTrue(selectedCount.label.contains("2 fingers selected"))
        capture("05-Two-winners")
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.staticTexts["game.selectionRule"].waitForExistence(timeout: 5))
        expectLabel(app.staticTexts["game.selectionRule"], "Keep 2 · 3+ players")
    }

    func testSixPlayerTeamsAndPickerSettingsPersist() {
        var app = launch()
        openOptions(app)
        app.buttons["settings.winnerCount.2"].tap()
        app.buttons["settings.mode.teams"].tap()
        XCTAssertTrue(app.buttons["settings.mode.teams"].isSelected)
        XCTAssertFalse(app.buttons["settings.winnerCount.2"].exists, "Teams mode hides the winner count")
        app.buttons["settings.players.6"].tap()
        reveal(app.buttons["settings.demo"], in: app)
        app.buttons["settings.demo"].tap()
        XCTAssertTrue(app.staticTexts["game.teamsResult"].waitForExistence(timeout: 12))
        for letter in ["A", "B"] {
            let team = app.descendants(matching: .any).matching(identifier: "game.team.\(letter)").firstMatch
            XCTAssertTrue(team.label.contains("Team \(letter), 3 players"))
        }
        capture("06-Three-versus-three")
        app.buttons["game.again"].tap()
        expectLabel(app.staticTexts["game.selectionRule"], "2 balanced teams · Wait for 6 players")
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.staticTexts["game.selectionRule"].waitForExistence(timeout: 5))
        expectLabel(app.staticTexts["game.selectionRule"], "2 balanced teams · Wait for 6 players")
        openOptions(app)
        XCTAssertTrue(app.buttons["settings.mode.teams"].isSelected)
        app.buttons["settings.mode.picker"].tap()
        XCTAssertTrue(app.buttons["settings.winnerCount.2"].isSelected)
        app.buttons["settings.players.auto"].tap()
        app.buttons["settings.done"].tap()
        expectLabel(app.staticTexts["game.selectionRule"], "Keep 2 · 3+ players")
    }

    func testOpeningOptionsCancelsDemoAndSwipeDismissReturnsToGame() {
        let app = launch()
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.countdown"].waitForExistence(timeout: 5))
        openOptions(app)
        app.buttons["settings.mode.teams"].tap()
        XCTAssertTrue(app.buttons["settings.mode.teams"].isSelected)
        // Dismiss interactively instead of relying on Done to apply the configuration.
        let start = app.staticTexts["settings.title"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.05, thenDragTo: end)
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                  object: app.buttons["settings.done"])
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        XCTAssertTrue(app.staticTexts["game.question"].waitForExistence(timeout: 3))
        expectLabel(app.staticTexts["game.question"], "Who teams up?")
        expectLabel(app.staticTexts["game.status"], "Waiting for players")
        XCTAssertFalse(app.staticTexts["game.teamsResult"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.staticTexts["game.winner"].exists)
    }

    func testTinyDareAddsAChallengeWithoutChangingTheWinner() {
        let app = launch()
        openOptions(app)
        reveal(app.buttons["settings.prompt.tinyDare"], in: app)
        app.buttons["settings.prompt.tinyDare"].tap()
        app.buttons["settings.done"].tap()
        expectLabel(app.staticTexts["game.question"], "Who's taking the challenge?")
        let board = app.otherElements["game.touchSurface"].frame
        startDemo(app)
        XCTAssertTrue(app.staticTexts["game.dare"].waitForExistence(timeout: 10))
        let dare = app.staticTexts["game.dare"].label
        let winner = app.staticTexts["game.winner"].label
        XCTAssertFalse(dare.isEmpty)
        XCTAssertEqual(app.otherElements["game.touchSurface"].frame, board)
        app.buttons["game.dare.shuffle"].tap()
        XCTAssertNotEqual(app.staticTexts["game.dare"].label, dare)
        XCTAssertEqual(app.staticTexts["game.winner"].label, winner)
        capture("07-Tiny-dare")
        app.buttons["game.again"].tap()
        XCTAssertFalse(app.staticTexts["game.dare"].exists)
        expectLabel(app.staticTexts["game.question"], "Who's taking the challenge?")
    }

    /// Sheet dismissal and replay re-render a moment after the tap, so wait for the label
    /// instead of reading it on the next line.
    private func expectLabel(_ element: XCUIElement, _ text: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let match = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", text), object: element)
        if XCTWaiter.wait(for: [match], timeout: 5) != .completed {
            XCTAssertEqual(element.label, text, file: file, line: line)
        }
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 {
            if element.isHittable { return }
            app.swipeUp()
        }
    }
}
