// Generated automatically by Perfect Assistant Application
// Date: 2017-08-13 19:01:21 +0000
import PackageDescription
let package = Package(
	name: "PostgresStORM",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 2),
	        .Package(url: "https://github.com/ryancoyne/StORM-ryan.git", majorVersion: 1),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-XML.git", majorVersion: 2),
		.Package(url: "https://github.com/PerfectlySoft/Perfect-Logger.git", majorVersion: 1),
	]
)
