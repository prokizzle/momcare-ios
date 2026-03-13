import XCTest

final class MomCareUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // App should launch successfully showing either onboarding or the main tab bar
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
