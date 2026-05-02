import XCTest

final class MomCareUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Synchronize on launch, then require an actionable app state.
        let splashTitle = app.staticTexts["MomCare"]
        let getStarted = app.buttons["Get Started"]
        let tabBar = app.tabBars.firstMatch
        let anyActionableButton = app.buttons.firstMatch
        _ = splashTitle.waitForExistence(timeout: 5)
        let readyStateExists = getStarted.waitForExistence(timeout: 10)
            || tabBar.waitForExistence(timeout: 10)
            || anyActionableButton.waitForExistence(timeout: 10)
        XCTAssertTrue(readyStateExists, "Expected actionable UI or main tab bar after launch")
    }
}
