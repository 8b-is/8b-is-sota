import XCTest
@testable import SOTAUI
import SOTACore

final class SOTAUITests: XCTestCase {

    func testOnboardingFlowShape() {
        let pages = SOTAOnboardingPage.all
        XCTAssertEqual(pages.count, 6)
        XCTAssertEqual(pages.first?.title, "Welcome to \(SOTAAppInfo.name)")
        XCTAssertEqual(pages.last?.title, "You're set")
        // Exactly one page offers the offline toggle, and one links the guide.
        XCTAssertEqual(pages.filter(\.showsOfflineToggle).count, 1)
        XCTAssertTrue(pages.contains { $0.guide == SOTAAppInfo.setupGuide })
    }

    func testAppInfoURLsParse() {
        XCTAssertEqual(SOTAAppInfo.setupGuide.absoluteString, SOTAAppInfo.setupGuideURL)
        XCTAssertEqual(SOTAAppInfo.version, "0.1.1")
    }

    func testPreferredKeyIsCapabilityScoped() {
        XCTAssertEqual(SOTAKeys.preferred(.infer), "sota.engine.infer")
        XCTAssertNotEqual(SOTAKeys.preferred(.infer), SOTAKeys.preferred(.recall))
    }
}
