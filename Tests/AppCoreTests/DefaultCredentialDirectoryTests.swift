import Foundation
import Testing
@testable import CalendarGatewayCore

@Test func defaultCredentialDirectoryUsesXDGStateHome() {
  let directory = CalendarGatewayConfigLoader.resolveDefaultCredentialDirectory(
    environment: ["XDG_STATE_HOME": "/tmp/xdg-state"]
  )
  #expect(directory == "/tmp/xdg-state/calendar-gateway/credentials")
}

@Test func defaultCredentialDirectoryDefaultsToLocalState() {
  let directory = CalendarGatewayConfigLoader.resolveDefaultCredentialDirectory(environment: [:])
  let home = FileManager.default.homeDirectoryForCurrentUser.path
  #expect(directory == "\(home)/.local/state/calendar-gateway/credentials")
}

@Test func credentialDirEnvironmentVariableOverridesStateDefault() {
  let directory = CalendarGatewayConfigLoader.resolveDefaultCredentialDirectory(
    environment: [
      "CALENDAR_GATEWAY_CREDENTIAL_DIR": "/tmp/riela-credentials",
      "XDG_STATE_HOME": "/tmp/xdg-state"
    ]
  )
  #expect(directory == "/tmp/riela-credentials")
}

@Test func synthesizedConfigStoresTokensUnderCredentialDirectory() throws {
  let scratch = FileManager.default.temporaryDirectory
    .appendingPathComponent("calendar-credential-dir-\(UUID().uuidString)", isDirectory: true)
  try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: scratch) }
  let missingConfig = scratch.appendingPathComponent("config/calendar-gateway/config.toml").path
  let config = try CalendarGatewayConfigLoader.loadConfig(
    environment: [
      "XDG_CONFIG_HOME": scratch.appendingPathComponent("config").path,
      "CALENDAR_GATEWAY_CREDENTIAL_DIR": "/tmp/riela-credentials"
    ]
  )
  _ = missingConfig
  #expect(config.credentials.first?.tokenStorePath == "/tmp/riela-credentials/google-personal.json")
}
