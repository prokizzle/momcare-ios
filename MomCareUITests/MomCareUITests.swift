import XCTest

final class MomCareUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // App should show either onboarding or the main tab bar
        let getStarted = app.buttons["Get Started"]
        let tabBar = app.tabBars.firstMatch
        let eitherExists = getStarted.waitForExistence(timeout: 5) || tabBar.exists
        XCTAssertTrue(eitherExists, "Expected either onboarding or main tab bar")
    }
}
