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

    func testBoardRouteTracksStoredPreferenceAndAuto() {
        let suite = "SOTA-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let row = RoutingBoardRow(capability: .infer, router: Router(),
                                  onDeviceOnly: true, maxLatencyMS: .infinity, store: defaults)
        XCTAssertEqual(row.route?.engine.id, "mlx-quant")
        defaults.set("project-zero", forKey: SOTAKeys.preferred(.infer))
        XCTAssertEqual(row.route?.engine.id, "project-zero")
        defaults.set("", forKey: SOTAKeys.preferred(.infer))
        XCTAssertEqual(row.route?.engine.id, "mlx-quant")
        defaults.set("mem8", forKey: SOTAKeys.preferred(.recall))
        XCTAssertEqual(row.route?.engine.id, "mlx-quant")
    }

    func testBoardRoutePreservesPolicyWithStoredOverride() {
        let suite = "SOTA-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("whisper-large", forKey: SOTAKeys.preferred(.transcribe))
        let row = RoutingBoardRow(capability: .transcribe, router: Router(),
                                  onDeviceOnly: true, maxLatencyMS: .infinity, store: defaults)
        XCTAssertEqual(row.route?.engine.id, "kotoro")
        defaults.set("project-zero", forKey: SOTAKeys.preferred(.infer))
        let limited = RoutingBoardRow(capability: .infer, router: Router(),
                                      onDeviceOnly: true, maxLatencyMS: 150, store: defaults)
        XCTAssertEqual(limited.route?.engine.id, "mlx-quant")
    }

    func testPickerDefaultsToAutoAndPreservesExistingSelection() {
        let suite = "SOTA-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let engines = Router.stack.filter { $0.capability == .infer }
        XCTAssertEqual(EngineRow(capability: .infer, engines: engines, store: defaults).preferred, "")
        defaults.set("project-zero", forKey: SOTAKeys.preferred(.infer))
        XCTAssertEqual(EngineRow(capability: .infer, engines: engines, store: defaults).preferred, "project-zero")
    }
}
