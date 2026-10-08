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
                    let route = router.route(cap, onDeviceOnly: onDeviceOnly, maxLatencyMS: latencyCap)
                    HStack(alignment: .firstTextBaseline) {
                        Text(cap.rawValue.capitalized).frame(width: 96, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(route?.engine.piece ?? "—").font(.callout)
                            if let r = route {
                                Text(r.reason).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let r = route {
                            Text(String(format: "%.2f", r.score))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }

            Section("Model overrides") {
                ForEach(Capability.allCases, id: \.self) { cap in
                    EngineRow(capability: cap, engines: router.engines.filter { $0.capability == cap })
                }
                Text("Leave on \"Auto\" to let the router decide.")
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

/// One per-capability preferred-engine override, persisted per capability.
private struct EngineRow: View {
    let capability: Capability
    let engines: [Engine]

    @AppStorage private var preferred: String

    init(capability: Capability, engines: [Engine]) {
        self.capability = capability
        self.engines = engines
        let defaultID = engines.first(where: { $0.onDevice })?.id ?? engines.first?.id ?? ""
        _preferred = AppStorage(wrappedValue: defaultID, SOTAKeys.preferred(capability))
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
