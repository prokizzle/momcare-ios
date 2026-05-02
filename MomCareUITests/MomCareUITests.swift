import XCTest

final class MomCareUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // App should show the splash, onboarding, or the redesigned main tab bar.
        let splashTitle = app.staticTexts["MomCare"]
        let getStarted = app.buttons["Get Started"]
        let tabBar = app.tabBars.firstMatch
        let eitherExists = splashTitle.waitForExistence(timeout: 5)
            || getStarted.waitForExistence(timeout: 10)
            || tabBar.waitForExistence(timeout: 10)
        XCTAssertTrue(eitherExists, "Expected splash, onboarding, or main tab bar")
    }
}
