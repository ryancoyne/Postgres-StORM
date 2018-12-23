// swift-tools-version:4.0

import PackageDescription
let package = Package(
	name: "PostgresStORM",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PostgresStORM",
            targets: ["PostgresStORM"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ryancoyne/Perfect-PostgreSQL.git", from: "3.0.0"),
        .package(url: "https://github.com/ryancoyne/StORM-ryan.git", from: "3.0.0"),
	.package(url: "https://github.com/PerfectlySoft/Perfect-Logger.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "PostgresStORM",
            dependencies: ["PerfectPostgeSQL", "StORM", "PerfectLogger"],
             path: "Sources"
        )
    ]
)
