// swift-tools-version:4.0

import PackageDescription
let package = Package(
	name: "PostgresStORM",
	dependencies: [
//        .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 3),
        .Package(url: "https://github.com/ryancoyne/Perfect-PostgreSQL", majorVersion: 3),
        .Package(url: "https://github.com/ryancoyne/StORM-ryan", majorVersion: 3),
//        .Package(url: "https://github.com/SwiftORM/StORM.git", majorVersion: 3),
//			  .Package(url: "https://github.com/PerfectlySoft/Perfect-XML.git", majorVersion: 3),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Logger.git", majorVersion: 3),
	],
    targets: [
        .target(
            name: "PostgresStORM",
            dependencies: ["PerfectPostgeSQL", "StORM", "PerfectLogger"]
        )
    ],
)
