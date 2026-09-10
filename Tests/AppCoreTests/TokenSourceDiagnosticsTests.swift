import Foundation
import Testing
@testable import CalendarGatewayCore

@Test func fallbackInlineTokenRejectsLoginBeforeBrowserAndExplainsSelection() throws {
  let paths = temporaryConfigPaths()
  defer { try? FileManager.default.removeItem(atPath: paths.root) }
  let jsonVariable = CalendarGatewayConfigLoader.getCredentialJSONEnvVarName(credentialId: "google-personal", valueKey: "token_store_json")
  let pathVariable = CalendarGatewayConfigLoader.getCredentialPathEnvVarName(credentialId: "google-personal", pathKey: "token_store_path")
  let environment = ["XDG_CONFIG_HOME": paths.root, jsonVariable: "private-inline-token", pathVariable: paths.token]
  let result = CalendarGatewayCLI().run(arguments: ["auth", "login", "--credential", "google-personal"], environment: environment)
  #expect(result.exitCode == CalendarGatewayExitCode.invalidCliUsage.rawValue)
  #expect(result.stderr.contains(jsonVariable))
  #expect(result.stderr.contains(pathVariable))
  #expect(!result.stderr.contains("private-inline-token"))
  #expect(!FileManager.default.fileExists(atPath: paths.token))
}

@Test func explicitConfigTokenPathOverrideAppearsInGraphQLError() throws {
  let paths = temporaryConfigPaths()
  defer { try? FileManager.default.removeItem(atPath: paths.root) }
  try writeConfig(paths: paths)
  let variable = CalendarGatewayConfigLoader.getCredentialPathEnvVarName(credentialId: "google-personal", pathKey: "token_store_path")
  var environment = env(paths: paths)
  environment[variable] = paths.root + "/missing-token.json"
  let result = CalendarGatewayCLI().run(
    arguments: ["--config", paths.config, "graphql", "--query", "{ events(calendarId: \"personal\", timeMin: \"2026-07-01T00:00:00Z\") { events { id } } }"],
    environment: environment
  )
  #expect(result.exitCode == CalendarGatewayExitCode.providerApiError.rawValue)
  #expect(result.stdout.contains(variable))
  #expect(result.stdout.contains("ENVIRONMENT_PATH"))
  #expect(result.stdout.contains("missing-token.json"))
}

@Test func fallbackConfigAndStatusSelectTheSameWritableTokenFile() throws {
  let paths = temporaryConfigPaths()
  defer { try? FileManager.default.removeItem(atPath: paths.root) }
  let variable = CalendarGatewayConfigLoader.getCredentialPathEnvVarName(credentialId: "google-personal", pathKey: "token_store_path")
  let environment = ["XDG_CONFIG_HOME": paths.root, variable: paths.token]
  let config = try CalendarGatewayConfigLoader.loadConfig(environment: environment)
  let details = try CalendarGatewayService(config: config).getAuthStatus(credentialId: "google-personal")
  #expect(details["tokenSource"] as? String == "ENVIRONMENT_PATH")
  #expect(details["tokenStorePath"] as? String == paths.token)
  #expect((details["tokenSourceHint"] as? String)?.contains(variable) == true)
  #expect(!FileManager.default.fileExists(atPath: config.configPath))
}
