import XCTest

final class LookFarUITests: XCTestCase {
    var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        if app.buttons["closeBreak"].waitForExistence(timeout: 2) { app.buttons["closeBreak"].tap() }
    }
    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func allowNotifications() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 3) {
            if alert.buttons["허용"].exists { alert.buttons["허용"].tap() }
            else if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap() }
        }
    }
    func reset() {
        app.tabBars.buttons["설정"].tap()
        let button = app.buttons["resetData"]
        app.swipeUp()
        app.swipeUp()
        if button.exists { button.tap(); app.buttons["초기화"].tap() }
        app.tabBars.buttons["타이머"].tap()
    }
    func test01IntervalPersistsAndScreenshots() throws {
        reset()
        XCTAssertTrue(app.buttons["interval20"].waitForExistence(timeout: 3))
        capture("01-timer-ko")
        app.buttons["interval30"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["interval30"].isSelected)
        app.buttons["interval20"].tap()
        app.buttons["customInterval"].tap()
        XCTAssertTrue(app.pickers["minutesPicker"].waitForExistence(timeout: 3))
        capture("02-custom-ko")
        app.buttons["이 간격으로 설정"].tap()
    }
    func test02StartRestoreAndCancel() throws {
        reset()
        app.buttons["startStop"].tap()
        allowNotifications()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 8))
        capture("03-countdown-ko")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 5))
        app.buttons["startStop"].tap()
        XCTAssertTrue(app.buttons["interval20"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["countdown"].exists)
    }
    func test03BackgroundExpirationAndSnooze() throws {
        reset()
        app.terminate()
        app.launchArguments += ["-UITestShortTimer"]
        app.launch()
        app.buttons["startStop"].tap()
        allowNotifications()
        XCUIDevice.shared.press(.home)
        sleep(6)
        app.activate()
        XCTAssertTrue(app.buttons["beginBreak"].waitForExistence(timeout: 5))
        app.buttons["snooze"].tap()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 5))
        app.buttons["startStop"].tap()
    }
    func test04CompleteBreakAndHistory() throws {
        reset()
        app.buttons["breakNow"].tap()
        XCTAssertTrue(app.buttons["beginBreak"].waitForExistence(timeout: 3))
        capture("04-rest-ko")
        app.buttons["beginBreak"].tap()
        let done = app.buttons["finishBreak"]
        XCTAssertTrue(done.waitForExistence(timeout: 25))
        capture("05-completed-ko")
        done.tap()
        app.tabBars.buttons["휴식 기록"].tap()
        XCTAssertTrue(app.staticTexts["먼 곳 보기 · 20초"].waitForExistence(timeout: 4))
        capture("06-history-ko")
        app.terminate()
        app.launch()
        app.tabBars.buttons["휴식 기록"].tap()
        XCTAssertTrue(app.staticTexts["먼 곳 보기 · 20초"].waitForExistence(timeout: 4))
    }
    func test05SettingsPrivacyAndReset() throws {
        app.tabBars.buttons["설정"].tap()
        capture("07-settings-ko")
        app.swipeUp()
        let privacy = app.buttons["privacyPolicy"]
        if !privacy.exists { app.swipeUp() }
        XCTAssertTrue(privacy.waitForExistence(timeout: 3))
        privacy.tap()
        capture("08-privacy-ko")
        app.navigationBars.buttons.firstMatch.tap()
        reset()
        app.tabBars.buttons["휴식 기록"].tap()
        XCTAssertTrue(app.staticTexts["첫 번째 쉼을 기다려요"].waitForExistence(timeout: 3))
    }
    func test06EnglishScreenshots() throws {
        app.terminate()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        capture("01-timer-en")
        app.buttons["breakNow"].tap()
        XCTAssertTrue(app.buttons["beginBreak"].waitForExistence(timeout: 3))
        capture("04-rest-en")
        app.buttons["closeBreak"].tap()
        app.tabBars.buttons["Settings"].tap()
        capture("07-settings-en")
    }
    func test07ReminderPresentation() throws {
        reset()
        app.terminate()
        app.launchArguments += ["-UITestShortTimer"]
        app.launch()
        app.buttons["startStop"].tap()
        XCTAssertTrue(app.buttons["beginBreak"].waitForExistence(timeout: 10))
        capture("09-reminder-ko")
        app.buttons["closeBreak"].tap()
        XCTAssertTrue(app.buttons["interval20"].waitForExistence(timeout: 4))
    }
    func test09WindowLandscape() throws {
        if app.staticTexts["countdown"].exists {
            app.buttons["startStop"].tap()
            app.swipeDown()
        }
        XCTAssertTrue(app.images["windowLandscape"].waitForExistence(timeout: 5))
        capture("12-window-landscape-ko")
        let start = app.buttons["startStop"]
        for _ in 0..<3 {
            if start.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(start.isHittable)
        start.tap()
        allowNotifications()
        XCTAssertTrue(app.staticTexts["countdown"].waitForExistence(timeout: 5))
        start.tap()
        XCTAssertFalse(app.staticTexts["countdown"].exists)
    }
    func test08AutomationGuide() throws {
        XCUIDevice.shared.orientation = .portrait
        app.tabBars.buttons["설정"].tap()
        let guide = app.descendants(matching: .any)["automationGuide"].firstMatch
        for _ in 0..<4 {
            if guide.exists && guide.isHittable { break }
            app.swipeUp()
        }
        capture("10-automation-settings-ko")
        XCTAssertTrue(guide.waitForExistence(timeout: 4), app.debugDescription)
        guide.tap()
        XCTAssertTrue(app.navigationBars[L10n.automationTitle].waitForExistence(timeout: 4))
        capture("11-automation-guide-ko")
        for _ in 0..<5 {
            if app.staticTexts["automationLimitations"].exists { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["automationLimitations"].waitForExistence(timeout: 3))
    }
}

private enum L10n { static let automationTitle = "앱 실행 시 자동 시작" }
