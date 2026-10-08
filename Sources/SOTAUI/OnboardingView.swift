import SwiftUI
import SOTACore

/// First-install onboarding for SOTA.app. Four honest steps, then you route.
/// Mirrors the guided walkthrough at https://setup.vaked.dev.
public struct OnboardingView: View {
    @State private var step = 0
    @AppStorage(SOTAKeys.onDeviceOnly) private var onDeviceOnly = true
    private let onFinish: () -> Void

    public init(onFinish: @escaping () -> Void = {}) {
        self.onFinish = onFinish
    }

    private var pages: [SOTAOnboardingPage] { SOTAOnboardingPage.all }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: pages[step].symbol)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.tint)
                        .padding(.top, 8)

                    Text(pages[step].title).font(.largeTitle.bold())
                    Text(pages[step].body)
                        .font(.body).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let bullets = pages[step].bullets {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(bullets, id: \.self) { Label($0, systemImage: "checkmark.circle").font(.callout) }
                        }
                    }

                    if pages[step].showsOfflineToggle {
                        Toggle("Keep everything on device", isOn: $onDeviceOnly)
                            .font(.callout)
                    }

                    if let link = pages[step].guide {
                        Link(destination: link) {
                            Label("Open the illustrated setup guide", systemImage: "book")
                        }
                        .font(.callout)
                    }
                }
                .frame(maxWidth: 480, alignment: .leading)
                .padding(28)
                .frame(maxWidth: .infinity)
            }

            Divider()

            HStack(spacing: 12) {
                Button("Skip") { finish() }.buttonStyle(.plain).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
                Spacer()
                if step > 0 { Button("Back") { step -= 1 } }
                Button(step == pages.count - 1 ? "Start" : "Continue") {
                    if step == pages.count - 1 { finish() } else { step += 1 }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(minWidth: 520, minHeight: 560)
    }

    private func finish() { onFinish() }
}

/// One page of onboarding. Plain data so both platforms reuse it and tests can
/// assert the flow's shape.
public struct SOTAOnboardingPage: Hashable {
    public let title: String
    public let body: String
    public let symbol: String
    public let bullets: [String]?
    public let showsOfflineToggle: Bool
    public let guide: URL?

    public static let all: [SOTAOnboardingPage] = [
        .init(title: "Welcome to \(SOTAAppInfo.name)",
              body: "One on-device desk for every job: transcribe, infer, quantize, recall, research, imagine. SOTA routes each request to the best instrument — and keeps it on your \(platformName).",
              symbol: "square.grid.2x2", bullets: nil, showsOfflineToggle: false, guide: nil),

        .init(title: platformSetupTitle,
              body: platformSetupBody,
              symbol: platformSetupSymbol, bullets: nil, showsOfflineToggle: false, guide: nil),

        .init(title: "Add a HuggingFace model",
              body: "Bring your own local model. Download it once from HuggingFace and it stays on-device.",
              symbol: "shippingbox",
              bullets: ["Local weights, no upload", "Runs in airplane mode", "Swap models any time"],
              showsOfflineToggle: false, guide: nil),

        .init(title: "Wire the Shortcut",
              body: "Add the SOTA Shortcut to run a job from anywhere — Share Sheet, a file, or a keystroke.",
              symbol: "command",
              bullets: ["Share Sheet → Route", "File → Route", "Keystroke → Route"],
              showsOfflineToggle: false, guide: SOTAAppInfo.setupGuide),

        .init(title: "Stay on device",
              body: "SOTA measures quality at speed, locally. The core is guarded in CI: a networking API in the core fails the build.",
              symbol: "lock.shield", bullets: nil, showsOfflineToggle: true, guide: nil),

        .init(title: "You're set",
              body: "Ask for an outcome; SOTA picks the engine. The whole trick is one score: quality / (1 + latency).",
              symbol: "sparkles", bullets: nil, showsOfflineToggle: false, guide: nil),
    ]

    private static var platformName: String {
        #if os(macOS)
        "Mac"
        #else
        "iPhone"
        #endif
    }

    private static var platformSetupTitle: String {
        #if os(macOS)
        "Point it at your Mac"
        #else
        "Turn on Apple Intelligence"
        #endif
    }

    private static var platformSetupBody: String {
        #if os(macOS)
        "Osaurus serves a local model on your Mac. Point SOTA at localhost:1337, or at any local engine you already run."
        #else
        "Enable Apple Intelligence in Settings so the on-device models are available to SOTA. Nothing leaves the phone."
        #endif
    }

    private static var platformSetupSymbol: String {
        #if os(macOS)
        "desktopcomputer"
        #else
        "iphone"
        #endif
    }
}
