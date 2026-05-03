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
        let next = app.buttons["Next"]
        let setup = app.buttons["Let's set up"]
        let startUsing = app.buttons["Start using MomCare"]
        let signInWithGoogle = app.buttons["Sign in with Google"]
        let tabBar = app.tabBars.firstMatch
        _ = splashTitle.waitForExistence(timeout: 5)
        let readyStateExists = getStarted.waitForExistence(timeout: 10)
            || next.waitForExistence(timeout: 10)
            || setup.waitForExistence(timeout: 10)
            || startUsing.waitForExistence(timeout: 10)
            || signInWithGoogle.waitForExistence(timeout: 10)
            || tabBar.waitForExistence(timeout: 10)
        XCTAssertTrue(readyStateExists, "Expected actionable UI or main tab bar after launch")
    }
}
