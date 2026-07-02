import Foundation
import Testing
@testable import CalendarGatewayCore

@Test func loopbackRedirectAcceptsLocalhostAndCallbackPath() throws {
  let redirect = try GoogleCalendarLoopbackRedirectURI("http://localhost:8765/callback")

  #expect(redirect.host == "127.0.0.1")
  #expect(redirect.port == 8765)
  #expect(redirect.path == "/callback")
}

@Test func loopbackRedirectRejectsNonLocalHosts() throws {
  let error = try requireCalendarGatewayError {
    _ = try GoogleCalendarLoopbackRedirectURI("https://example.com/callback")
  }

  #expect(error.exitCode == .authenticationBootstrapError)
  #expect(error.message.contains("loopback URL"))
}

@Test func googleAuthorizationURLUsesFixedRedirectURIAndCalendarScopes() throws {
  let credential = testCredential(accessMode: .read)
  let client = GoogleOAuthClient(
    clientId: "client-id",
    clientSecret: "secret",
    authURI: "https://accounts.example.test/o/oauth2/auth",
    tokenURI: "https://tokens.example.test/token"
  )

  let url = try buildGoogleCalendarAuthorizationURLForTesting(
    client: client,
    credential: credential,
    redirectURI: "http://127.0.0.1:8765/callback",
    state: "state-value",
    codeVerifier: "verifier-value"
  )
  let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
  let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

  #expect(query["client_id"] == "client-id")
  #expect(query["redirect_uri"] == "http://127.0.0.1:8765/callback")
  #expect(query["state"] == "state-value")
  #expect(query["code_challenge_method"] == "S256")
  #expect(query["scope"]?.contains("https://www.googleapis.com/auth/calendar.events.readonly") == true)
  #expect(query["scope"]?.contains("https://www.googleapis.com/auth/calendar.calendarlist.readonly") == true)
  #expect(query["scope"]?.contains("https://www.googleapis.com/auth/calendar.freebusy") == true)
}
