import XCTest

final class MomCareUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify tab bar is present
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
