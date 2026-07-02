import Testing
@testable import CalendarGatewayCore

@Test func globalHelpAndVersionRejectUnknownFlagsAndValues() {
  let versionWithUnknown = CalendarGatewayCLI().run(arguments: ["--version", "--unknown"], environment: [:])
  let helpWithUnknown = CalendarGatewayCLI().run(arguments: ["--help", "--unknown"], environment: [:])
  let versionWithValue = CalendarGatewayCLI().run(arguments: ["--version=false"], environment: [:])
  let helpWithValue = CalendarGatewayCLI().run(arguments: ["--help=false"], environment: [:])

  #expect(versionWithUnknown.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(helpWithUnknown.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(versionWithValue.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(helpWithValue.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(versionWithUnknown.stderr.contains("Unknown flag: --unknown"))
  #expect(helpWithUnknown.stderr.contains("Unknown flag: --unknown"))
  #expect(versionWithValue.stderr.contains("--version does not accept a value"))
  #expect(helpWithValue.stderr.contains("--help does not accept a value"))
}

@Test func commandRejectsDuplicateFlagsBeforeRunning() {
  let version = CalendarGatewayCLI().run(arguments: ["--version", "--version"], environment: [:])
  let graphql = CalendarGatewayCLI().run(
    arguments: [
      "graphql",
      "--query", "{ calendars { id } }",
      "--query", "{ calendars { provider } }"
    ],
    environment: [:]
  )
  let cache = CalendarGatewayCLI().run(arguments: ["cache", "prune", "--all", "--all"], environment: [:])

  #expect(version.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(graphql.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(cache.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(version.stderr.contains("Duplicate flag: --version"))
  #expect(graphql.stderr.contains("Duplicate flag: --query"))
  #expect(cache.stderr.contains("Duplicate flag: --all"))
}

@Test func openBrowserFlagParsesAsBooleanAuthOption() throws {
  let enabled = try parseArguments(["auth", "login", "--credential", "google-personal", "--open-browser"])
  let disabled = try parseArguments(["auth", "login", "--credential", "google-personal", "--open-browser", "false"])

  #expect(try getBooleanFlag(enabled.flags, "open-browser"))
  #expect(try getBooleanFlag(disabled.flags, "open-browser") == false)
}

@Test func timeoutSecondsFlagRequiresInteger() {
  let result = CalendarGatewayCLI().run(
    arguments: [
      "auth",
      "login",
      "--credential", "google-personal",
      "--timeout-seconds", "never"
    ],
    environment: [:]
  )

  #expect(result.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(result.stderr.contains("--timeout-seconds must be an integer between 1 and 3600"))
}
