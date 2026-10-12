import SwiftUI
import SOTACore

/// The epic settings surface for SOTA.app: routing policy, per-capability
/// engine overrides, integrations, sync, and about.
public struct SettingsView: View {
    @AppStorage(SOTAKeys.onDeviceOnly) private var onDeviceOnly = true
    @AppStorage(SOTAKeys.maxLatencyMS) private var maxLatencyMS = 0.0 // 0 = no cap
    @AppStorage(SOTAKeys.portailEndpoint) private var portailEndpoint = "http://127.0.0.1:8787"
    @AppStorage(SOTAKeys.iCloudSync) private var iCloudSync = false

    private let router: Router

    public init(router: Router = Router()) { self.router = router }

    private var latencyCap: Double { maxLatencyMS <= 0 ? .infinity : maxLatencyMS }

    public var body: some View {
        Form {
            Section("Routing") {
                Toggle("On-device engines only", isOn: $onDeviceOnly)
                HStack {
                    Text("Max latency")
                    Spacer()
                    if maxLatencyMS <= 0 {
                        Text("no cap").foregroundStyle(.secondary)
                    } else {
                        Text("\(Int(maxLatencyMS)) ms").font(.system(.body, design: .monospaced))
                    }
                }
                Slider(value: $maxLatencyMS, in: 0...3000, step: 50)
                Button("Reset to no cap") { maxLatencyMS = 0 }
                    .buttonStyle(.plain).font(.caption)
            }

            Section("The board") {
                ForEach(Capability.allCases, id: \.self) { cap in
                    RoutingBoardRow(capability: cap, router: router,
                                    onDeviceOnly: onDeviceOnly, maxLatencyMS: latencyCap)
                }
            }

            Section("Model overrides") {
                ForEach(Capability.allCases, id: \.self) { cap in
                    EngineRow(capability: cap, engines: router.engines.filter { $0.capability == cap })
                }
                Text("Auto picks the highest-scoring engine. If your choice is unavailable or excluded by the routing limits, Auto is used.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("Integrations") {
                TextField("Portail endpoint", text: $portailEndpoint)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Sync") {
                Toggle("Sync routing history with iCloud", isOn: $iCloudSync)
            }

            Section("About") {
                LabeledContent("Version", value: SOTAAppInfo.version)
                Link("Setup guide", destination: SOTAAppInfo.setupGuide)
                Link("Landing", destination: SOTAAppInfo.landing)
                Link("Source", destination: SOTAAppInfo.source)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 620)
    }
}

/// Observe the same capability preference as the picker so the displayed route
/// refreshes when the selection changes.
struct RoutingBoardRow: View {
    let capability: Capability
    let router: Router
    let onDeviceOnly: Bool
    let maxLatencyMS: Double
    @AppStorage private var preferred: String

    init(capability: Capability, router: Router, onDeviceOnly: Bool,
         maxLatencyMS: Double, store: UserDefaults? = nil) {
        self.capability = capability
        self.router = router
        self.onDeviceOnly = onDeviceOnly
        self.maxLatencyMS = maxLatencyMS
        _preferred = AppStorage(wrappedValue: "", SOTAKeys.preferred(capability), store: store)
    }

    var route: Route? {
        router.route(capability, onDeviceOnly: onDeviceOnly, maxLatencyMS: maxLatencyMS,
                     preferredEngineID: preferred)
    }

    var body: some View {
        let result = route
        HStack(alignment: .firstTextBaseline) {
            Text(capability.rawValue.capitalized).frame(width: 96, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(result?.engine.piece ?? "—").font(.callout)
                if let r = result {
                    Text(r.reason).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let r = result {
                Text(String(format: "%.2f", r.score))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tint)
            }
        }
    }
}

/// One per-capability preferred-engine override, persisted per capability.
struct EngineRow: View {
    let capability: Capability
    let engines: [Engine]

    @AppStorage var preferred: String

    init(capability: Capability, engines: [Engine], store: UserDefaults? = nil) {
        self.capability = capability
        self.engines = engines
        _preferred = AppStorage(wrappedValue: "", SOTAKeys.preferred(capability), store: store)
    }

    var body: some View {
        Picker(capability.rawValue.capitalized, selection: $preferred) {
            Text("Auto").tag("")
            ForEach(engines, id: \.id) { e in
                Text(e.piece).tag(e.id)
            }
        }
    }
}
