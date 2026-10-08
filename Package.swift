// swift-tools-version:6.3
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .strictMemorySafety(),
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableExperimentalFeature("SuppressedAssociatedTypes"),
    .enableExperimentalFeature("LifetimeDependence"),
    .enableExperimentalFeature("Lifetimes"),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "feather-storage-s3",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "FeatherStorageS3", targets: ["FeatherStorageS3"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.14.0"),
        .package(url: "https://github.com/soto-project/soto-core", from: "7.17.0"),
        .package(
            url: "https://github.com/feather-framework/feather-storage",
            exact: "1.0.0-rc.2"
        ),
    ],
    targets: [
        .target(
            name: "FeatherSotoS3",
            dependencies: [
                .product(name: "SotoCore", package: "soto-core"),
            ],
            exclude: [
                "s3-2006-03-01.json",
                "soto.config.json",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "FeatherStorageS3",
            dependencies: [
                .product(name: "FeatherStorage", package: "feather-storage"),
                .target(name: "FeatherSotoS3"),
                .product(name: "SotoCore", package: "soto-core"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "FeatherStorageS3Tests",
            dependencies: [
                .target(name: "FeatherStorageS3"),
                .target(name: "FeatherSotoS3"),
                .product(name: "FeatherStorage", package: "feather-storage"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
