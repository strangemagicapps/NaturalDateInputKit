// swift-tools-version: 6.3

import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "NaturalDateInputKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "NaturalDateInputKit", targets: ["NaturalDateInputKit"]),
        .library(name: "NaturalDateInputKitUI", targets: ["NaturalDateInputKitUI"]),
    ],
    targets: [
        .target(
            name: "NaturalDateInputKit",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "NaturalDateInputKitUI",
            dependencies: ["NaturalDateInputKit"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "NaturalDateInputKitTests",
            dependencies: ["NaturalDateInputKit"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "NaturalDateInputKitUITests",
            dependencies: ["NaturalDateInputKitUI"],
            swiftSettings: strictConcurrency
        ),
    ],
    swiftLanguageModes: [.v6]
)
