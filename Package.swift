// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "calendar-gateway",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "CalendarGatewayCore", targets: ["CalendarGatewayCore"]),
    .executable(name: "calendar-gateway", targets: ["CalendarGatewayCLI"])
  ],
  targets: [
    .target(name: "CalendarGatewayCore"),
    .executableTarget(
      name: "CalendarGatewayCLI",
      dependencies: ["CalendarGatewayCore"],
      path: "Sources/AppCLI"
    ),
    .testTarget(
      name: "CalendarGatewayCoreTests",
      dependencies: ["CalendarGatewayCore"],
      path: "Tests/AppCoreTests"
    )
  ],
  swiftLanguageModes: [.v6]
)
