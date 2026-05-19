// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NaturalDateInputKit",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NaturalDateInputKit",
            targets: ["NaturalDateInputKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NaturalDateInputKit"
        ),
        .testTarget(
            name: "NaturalDateInputKitTests",
            dependencies: ["NaturalDateInputKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
