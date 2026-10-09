import XCTest
@testable import SOTACore

final class SOTACoreTests: XCTestCase {

    func testRoutesTranscribeToKotoro() {
        let r = Router().route(.transcribe)
        XCTAssertEqual(r?.engine.id, "kotoro")
        XCTAssertTrue(r?.engine.onDevice ?? false)
    }

    func testRoutesInferToMetal() {
        // 4-bit Metal beats 1.58-bit CPU here — more quality at still-low latency.
        let r = Router().route(.infer)
        XCTAssertEqual(r?.engine.id, "mlx-quant")
    }

    func testOnDeviceOnlyExcludesCloud() {
        let cloud = Router().route(.transcribe, onDeviceOnly: false)
        XCTAssertNotNil(cloud)                       // still picks the best (kotoro, on device)
        XCTAssertEqual(cloud?.engine.id, "kotoro")   // on-device wins even when cloud allowed
    }

    func testMaxLatencyConstrains() {
        let fast = Router().route(.infer, maxLatencyMS: 150)
        XCTAssertEqual(fast?.engine.id, "mlx-quant") // 140 ms fits; CPU 210 ms does not
        let veryFast = Router().route(.infer, maxLatencyMS: 100)
        XCTAssertNil(veryFast)                       // nothing that fast for infer
    }

    func testRecallGoesToMem8() {
        XCTAssertEqual(Router().route(.recall)?.engine.id, "mem8")
    }

    func testSotaIsQualityAtSpeed() {
        let router = Router()
        let a = Engine(id: "slow", piece: "slow", capability: .infer, bits: 8, latencyMS: 2000, quality: 1.0, onDevice: true)
        let b = Engine(id: "fast", piece: "fast", capability: .infer, bits: 8, latencyMS: 100, quality: 0.9, onDevice: true)
        XCTAssertGreaterThan(router.sota(b), router.sota(a))  // speed wins when quality is close
    }

    func testBoardCoversEveryCapability() {
        let board = Router().board()
        XCTAssertEqual(board.count, Capability.allCases.count)
        XCTAssertTrue(board.allSatisfy { $0.1 != nil })
    }

    func testEligiblePreferenceOverridesScore() {
        let router = Router()
        let route = router.route(.infer, preferredEngineID: "project-zero")
        XCTAssertEqual(route?.engine.id, "project-zero")
        XCTAssertEqual(route?.score, router.sota(Router.stack.first { $0.id == "project-zero" }!))
    }

    func testAutoAndUnavailablePreferencesUseScoring() {
        for preference: String? in [nil, "", "removed-engine", "mem8"] {
            XCTAssertEqual(Router().route(.infer, preferredEngineID: preference)?.engine.id, "mlx-quant")
        }
    }

    func testPreferenceCannotBypassOnDevicePolicy() {
        let router = Router()
        XCTAssertEqual(router.route(.transcribe, preferredEngineID: "whisper-large")?.engine.id, "kotoro")
        XCTAssertEqual(router.route(.transcribe, onDeviceOnly: false,
                                    preferredEngineID: "whisper-large")?.engine.id, "whisper-large")
    }

    func testPreferenceCannotBypassLatencyCap() {
        let router = Router()
        XCTAssertEqual(router.route(.infer, maxLatencyMS: 150,
                                    preferredEngineID: "project-zero")?.engine.id, "mlx-quant")
        XCTAssertEqual(router.route(.infer, maxLatencyMS: 210,
                                    preferredEngineID: "project-zero")?.engine.id, "project-zero")
        XCTAssertNil(router.route(.infer, maxLatencyMS: 100, preferredEngineID: "project-zero"))
    }
}
