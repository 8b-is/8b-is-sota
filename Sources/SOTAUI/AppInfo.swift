import Foundation
import SOTACore

/// Shared UI facts for SOTA.app.
public enum SOTAAppInfo {
    public static let name = "SOTA.app"
    public static let version = "0.1.1"

    public static let landingURL = "https://sota.vaked.dev"
    public static let setupGuideURL = "https://setup.vaked.dev"
    public static let sourceURL = "https://github.com/8b-is/8b-is-sota"

    public static var landing: URL { URL(string: landingURL)! }
    public static var setupGuide: URL { URL(string: setupGuideURL)! }
    public static var source: URL { URL(string: sourceURL)! }
}

public enum SOTAKeys {
    public static let didOnboard = "sota.didOnboard"
    public static let onDeviceOnly = "sota.onDeviceOnly"
    public static let maxLatencyMS = "sota.maxLatencyMS"
    public static let portailEndpoint = "sota.portailEndpoint"
    public static let iCloudSync = "sota.iCloudSync"

    public static func preferred(_ c: Capability) -> String { "sota.engine.\(c.rawValue)" }
}
