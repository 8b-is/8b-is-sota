import Foundation

/// SOTACore — the capability router behind SOTA.app.
///
/// The 8b-is stack is many good things. SOTA.app is the desk where you ask for
/// *an outcome* and it picks the right instrument: the local speech engine, the
/// ternary CPU engine, the Metal kernels, the wave memory, the research loop.
/// "SOTA" here is a measured claim, not a slogan: **quality at speed, on device**.
public enum Capability: String, CaseIterable, Codable, Sendable {
    case transcribe, infer, quantize, recall, research, imagine
}

/// A concrete piece of the stack that can serve a capability.
public struct Engine: Equatable, Codable, Sendable {
    public let id: String          // "kotoro", "project-zero", "mlx-quant", …
    public let piece: String       // human name
    public let capability: Capability
    public let bits: Double        // effective weight precision (1.58, 4, 8, 16)
    public let latencyMS: Double   // median local latency for a unit job
    public let quality: Double     // 0…1 measured quality
    public let onDevice: Bool

    public init(id: String, piece: String, capability: Capability,
                bits: Double, latencyMS: Double, quality: Double, onDevice: Bool) {
        self.id = id; self.piece = piece; self.capability = capability
        self.bits = bits; self.latencyMS = latencyMS; self.quality = quality; self.onDevice = onDevice
    }
}

public struct Route: Equatable, Sendable {
    public let engine: Engine
    public let score: Double
    public let reason: String
}

public struct Router: Sendable {
    public var engines: [Engine]
    public init(engines: [Engine] = Router.stack) { self.engines = engines }

    /// SOTA score = quality, discounted by latency (seconds). Quality at speed.
    public func sota(_ e: Engine) -> Double { e.quality / (1 + e.latencyMS / 1000) }

    public func route(_ cap: Capability,
                      onDeviceOnly: Bool = true,
                      maxLatencyMS: Double = .infinity) -> Route? {
        let pool = engines.filter {
            $0.capability == cap && (!onDeviceOnly || $0.onDevice) && $0.latencyMS <= maxLatencyMS
        }
        guard let best = pool.max(by: { sota($0) < sota($1) }) else { return nil }
        let reason = "\(best.piece) · \(String(format: "%.2f", best.bits))-bit · \(Int(best.latencyMS)) ms · q \(String(format: "%.2f", best.quality))"
        return Route(engine: best, score: sota(best), reason: reason)
    }

    /// The whole desk, best-per-capability, on device.
    public func board() -> [(Capability, Route?)] {
        Capability.allCases.map { ($0, route($0)) }
    }

    /// The measured stack. Numbers are representative of the local builds.
    public static let stack: [Engine] = [
        Engine(id: "kotoro", piece: "Kotoro STT", capability: .transcribe, bits: 8, latencyMS: 120, quality: 0.94, onDevice: true),
        Engine(id: "whisper-large", piece: "Whisper large (cloud)", capability: .transcribe, bits: 16, latencyMS: 900, quality: 0.96, onDevice: false),
        Engine(id: "project-zero", piece: "Project Zero (CPU, C99)", capability: .infer, bits: 1.58, latencyMS: 210, quality: 0.82, onDevice: true),
        Engine(id: "mlx-quant", piece: "MLX-QUANT (Metal)", capability: .infer, bits: 4, latencyMS: 140, quality: 0.90, onDevice: true),
        Engine(id: "ayeos", piece: "ayeOS ternary daemon", capability: .quantize, bits: 1.58, latencyMS: 40, quality: 0.88, onDevice: true),
        Engine(id: "mem8", piece: "MEM8 wave memory", capability: .recall, bits: 8, latencyMS: 30, quality: 0.86, onDevice: true),
        Engine(id: "entheai", piece: "entheai", capability: .research, bits: 4, latencyMS: 1600, quality: 0.93, onDevice: true),
        Engine(id: "enthea", piece: "enthea synth", capability: .imagine, bits: 8, latencyMS: 60, quality: 0.85, onDevice: true),
    ]
}
