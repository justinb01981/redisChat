import PackageDescription

let package = Package(
    name: "Project",
    dependencies: [
        .Package(url: "https://github.com/vapor/redis.git", majorVersion: 2)
    ]
)