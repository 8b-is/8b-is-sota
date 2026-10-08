// swift-tools-version: 5.9
import PackageDescription

// SOTA.app — the 8b-is flagship.
// One on-device brain that routes every job to the best piece of the stack:
// transcribe -> Kotoro, infer -> Project Zero / MLX-QUANT, recall -> MEM8,
// research -> entheai, imagine -> enthea. The router scores "SOTA" as quality
// at speed, and never sends your data off the device.
let package = Package(
    name: "SOTA",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SOTACore", targets: ["SOTACore"]),
    ],
    targets: [
        .target(name: "SOTACore"),
        .testTarget(name: "SOTACoreTests", dependencies: ["SOTACore"]),
    ]
)
