import Foundation
import Testing
@testable import CalendarGatewayCore

struct FakeCalendarProvider: CalendarEventProvider {
  func listCalendars(credential: CalendarCredentialConfig) throws -> [ProviderCalendarInfo] {
    [
      ProviderCalendarInfo(
        id: "primary",
        summary: "Personal",
        timeZone: "UTC",
        accessRole: "owner",
        isPrimary: true,
        isSelected: true,
        providerMetadata: ["fake": ["credentialId": credential.id]]
      ),
      ProviderCalendarInfo(
        id: "team@example.com",
        summary: "Team",
        timeZone: "UTC",
        accessRole: "writer",
        isSelected: true,
        providerMetadata: ["fake": ["credentialId": credential.id]]
      )
    ]
  }

  func listEvents(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    search: CalendarEventSearch
  ) throws -> CalendarEventConnection {
    let calendarId = search.calendarId ?? account.defaultCalendarId
    if let pageToken = search.pageToken {
      #expect(pageToken == "next-page")
    }
    let fakeMetadata: [String: Any] = [
      "credentialId": credential.id,
      "updatedMin": search.updatedMin as Any? ?? NSNull(),
      "syncToken": search.syncToken as Any? ?? NSNull(),
      "showDeleted": search.showDeleted as Any? ?? NSNull(),
      "singleEvents": search.singleEvents,
      "orderBy": search.orderBy?.rawValue as Any? ?? NSNull()
    ]
    return CalendarEventConnection(
      accountId: account.id,
      calendarId: calendarId,
      events: [
        CalendarEvent(
          id: "event-1",
          accountId: account.id,
          calendarId: calendarId,
          summary: "Planning",
          start: CalendarEventDateTime(dateTime: "2026-07-01T09:00:00Z", timeZone: "UTC"),
          end: CalendarEventDateTime(dateTime: "2026-07-01T09:30:00Z", timeZone: "UTC"),
          attendees: [CalendarEventParticipant(email: "guest@example.com", responseStatus: "accepted")],
          providerMetadata: ["fake": fakeMetadata]
        )
      ],
      nextPageToken: "next-page",
      nextSyncToken: "next-sync"
    )
  }

  func getEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String
  ) throws -> CalendarEvent {
    CalendarEvent(
      id: eventId,
      accountId: account.id,
      calendarId: calendarId,
      providerMetadata: ["fake": ["credentialId": credential.id]]
    )
  }

  func queryFreeBusy(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    query: CalendarFreeBusyQuery
  ) throws -> CalendarFreeBusyResponse {
    CalendarFreeBusyResponse(
      accountId: account.id,
      timeMin: query.timeMin,
      timeMax: query.timeMax,
      calendars: query.calendarIds.map { calendarId in
        CalendarFreeBusyCalendar(
          id: calendarId,
          busy: [
            CalendarFreeBusyInterval(start: "2026-07-01T09:00:00Z", end: "2026-07-01T09:30:00Z")
          ],
          providerMetadata: ["fake": ["credentialId": credential.id]]
        )
      },
      providerMetadata: ["fake": ["credentialId": credential.id]]
    )
  }

  func createEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    CalendarEvent(
      id: "created-event",
      accountId: account.id,
      calendarId: input.calendarId ?? account.defaultCalendarId,
      summary: input.summary,
      colorId: input.colorId,
      visibility: input.visibility,
      transparency: input.transparency,
      recurrenceRules: input.recurrenceRules,
      reminders: CalendarEventReminders(
        useDefault: input.reminderUseDefault,
        overrides: input.reminderOverrides
      ),
      conferenceData: input.createConference ? CalendarConferenceData(
        conferenceId: "meet-123",
        solutionType: "hangoutsMeet",
        solutionName: "Google Meet",
        createRequestStatus: "success",
        entryPoints: [CalendarConferenceEntryPoint(entryPointType: "video", uri: "https://meet.google.com/aaa-bbbb-ccc")]
      ) : nil,
      providerMetadata: ["fake": ["credentialId": credential.id]]
    )
  }

  func updateEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    CalendarEvent(
      id: input.eventId,
      accountId: account.id,
      calendarId: input.calendarId ?? account.defaultCalendarId,
      summary: input.summary,
      colorId: input.colorId,
      visibility: input.visibility,
      transparency: input.transparency,
      recurrenceRules: input.recurrenceRules,
      reminders: CalendarEventReminders(
        useDefault: input.reminderUseDefault,
        overrides: input.reminderOverrides
      ),
      conferenceData: input.createConference ? CalendarConferenceData(
        conferenceId: "meet-123",
        solutionType: "hangoutsMeet",
        solutionName: "Google Meet",
        createRequestStatus: "success",
        entryPoints: [CalendarConferenceEntryPoint(entryPointType: "video", uri: "https://meet.google.com/aaa-bbbb-ccc")]
      ) : nil,
      providerMetadata: ["fake": ["credentialId": credential.id]]
    )
  }

  func deleteEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String,
    sendUpdates: String?
  ) throws -> [String: Any] {
    [
      "accountId": account.id,
      "credentialId": credential.id,
      "calendarId": calendarId,
      "eventId": eventId,
      "sendUpdates": sendUpdates as Any? ?? NSNull(),
      "deleted": true
    ]
  }

  func executeCalendarAPI(
    credential: CalendarCredentialConfig,
    request: CalendarRawAPIRequest
  ) throws -> [String: Any] {
    [
      "status": 200,
      "body": [
        "credentialId": credential.id,
        "method": request.method.rawValue,
        "path": request.path,
        "query": Dictionary(uniqueKeysWithValues: request.queryItems),
        "body": request.bodyJSON.flatMap { try? parseRawCalendarAPIJSONBody($0) } as Any? ?? NSNull(),
        "access": request.access.rawValue
      ]
    ]
  }
}

struct FailingWriteProvider: CalendarEventProvider {
  func listCalendars(credential: CalendarCredentialConfig) throws -> [ProviderCalendarInfo] {
    []
  }

  func listEvents(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    search: CalendarEventSearch
  ) throws -> CalendarEventConnection {
    CalendarEventConnection(accountId: account.id, calendarId: account.defaultCalendarId, events: [])
  }

  func getEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String
  ) throws -> CalendarEvent {
    CalendarEvent(id: eventId, accountId: account.id, calendarId: calendarId)
  }

  func queryFreeBusy(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    query: CalendarFreeBusyQuery
  ) throws -> CalendarFreeBusyResponse {
    CalendarFreeBusyResponse(
      accountId: account.id,
      timeMin: query.timeMin,
      timeMax: query.timeMax,
      calendars: []
    )
  }

  func createEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    Issue.record("Provider write should not be called")
    return CalendarEvent(accountId: account.id, calendarId: account.defaultCalendarId)
  }

  func updateEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    Issue.record("Provider write should not be called")
    return CalendarEvent(accountId: account.id, calendarId: account.defaultCalendarId)
  }

  func deleteEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String,
    sendUpdates: String?
  ) throws -> [String: Any] {
    Issue.record("Provider write should not be called")
    return [:]
  }

  func executeCalendarAPI(
    credential: CalendarCredentialConfig,
    request: CalendarRawAPIRequest
  ) throws -> [String: Any] {
    Issue.record("Provider raw API write should not be called")
    return [:]
  }
}

struct ThrowingReadProvider: CalendarEventProvider {
  func listCalendars(credential: CalendarCredentialConfig) throws -> [ProviderCalendarInfo] {
    throw rateLimitedError()
  }

  func listEvents(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    search: CalendarEventSearch
  ) throws -> CalendarEventConnection {
    throw rateLimitedError()
  }

  func getEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String
  ) throws -> CalendarEvent {
    throw rateLimitedError()
  }

  func queryFreeBusy(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    query: CalendarFreeBusyQuery
  ) throws -> CalendarFreeBusyResponse {
    throw rateLimitedError()
  }

  func createEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    CalendarEvent(id: "created-event", accountId: account.id, calendarId: input.calendarId ?? account.defaultCalendarId)
  }

  func updateEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    input: CalendarEventInput
  ) throws -> CalendarEvent {
    CalendarEvent(id: input.eventId, accountId: account.id, calendarId: input.calendarId ?? account.defaultCalendarId)
  }

  func deleteEvent(
    account: CalendarAccountConfig,
    credential: CalendarCredentialConfig,
    calendarId: String,
    eventId: String,
    sendUpdates: String?
  ) throws -> [String: Any] {
    ["deleted": true]
  }

  func executeCalendarAPI(
    credential: CalendarCredentialConfig,
    request: CalendarRawAPIRequest
  ) throws -> [String: Any] {
    throw rateLimitedError()
  }

  private func rateLimitedError() -> CalendarGatewayError {
    CalendarGatewayError(
      "Google Calendar rate limit exceeded",
      code: .providerRateLimited,
      exitCode: .providerApiError
    )
  }
}

struct TestConfigPaths {
  let root: String
  let config: String
  let oauthClient: String
  let token: String
  let cache: String
}

func temporaryConfigPaths() -> TestConfigPaths {
  let root = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("calendar-gateway-tests-\(UUID().uuidString)", isDirectory: true)
  return TestConfigPaths(
    root: root.path,
    config: root.appendingPathComponent("config.toml").path,
    oauthClient: root.appendingPathComponent("google-client.json").path,
    token: root.appendingPathComponent("token.json").path,
    cache: root.appendingPathComponent("cache", isDirectory: true).path
  )
}

func writeConfig(paths: TestConfigPaths, accessMode: String = "read") throws {
  try FileManager.default.createDirectory(atPath: paths.root, withIntermediateDirectories: true)
  try """
  {"installed":{"client_id":"client","auth_uri":"https://accounts.example.test/auth","token_uri":"https://tokens.example.test/token"}}
  """.write(toFile: paths.oauthClient, atomically: true, encoding: .utf8)
  try """
  {"accessMode":"read","accessToken":"test-token","refreshToken":"refresh","expiresAt":"2099-01-01T00:00:00Z","scope":"https://www.googleapis.com/auth/calendar.events.readonly https://www.googleapis.com/auth/calendar.calendarlist.readonly https://www.googleapis.com/auth/calendar.freebusy"}
  """.write(toFile: paths.token, atomically: true, encoding: .utf8)
  try """
  [storage]
  cache_dir = "\(paths.cache)"

  [[credentials]]
  id = "google-personal"
  provider = "google"
  access_mode = "\(accessMode)"
  oauth_client_secret_path = "\(paths.oauthClient)"
  token_store_path = "\(paths.token)"

  [[calendars]]
  id = "personal"
  display_name = "Personal"
  provider = "google"
  credential_id = "google-personal"
  calendar_id = "primary"
  default_time_zone = "UTC"
  """.write(toFile: paths.config, atomically: true, encoding: .utf8)
}

func env(paths: TestConfigPaths) -> [String: String] {
  [
    "CALENDAR_GATEWAY_CREDENTIAL_GOOGLE_PERSONAL_OAUTH_CLIENT_SECRET_PATH": paths.oauthClient,
    "CALENDAR_GATEWAY_CREDENTIAL_GOOGLE_PERSONAL_TOKEN_STORE_PATH": paths.token
  ]
}

func requireCalendarGatewayError(_ operation: () throws -> Void) throws -> CalendarGatewayError {
  do {
    try operation()
  } catch let error as CalendarGatewayError {
    return error
  } catch {
    Issue.record("Unexpected error: \(error)")
  }
  Issue.record("Expected CalendarGatewayError")
  throw CalendarGatewayError("Expected test error", code: .invalidArgument, exitCode: .generalError)
}

func testCredential(
  oauthClientSecretJSON: String = "{}",
  tokenStoreJSON: String = "{}",
  accessMode: CalendarAccessMode = .read
) -> CalendarCredentialConfig {
  CalendarCredentialConfig(
    id: "google-personal",
    provider: .google,
    accessMode: accessMode,
    oauthClientSecretPath: "/tmp/google-client.json",
    oauthClientSecretJSON: oauthClientSecretJSON,
    tokenStorePath: "/tmp/token.json",
    tokenStoreJSON: tokenStoreJSON
  )
}

func testConfig(accessMode: CalendarAccessMode = .read) -> CalendarGatewayConfig {
  CalendarGatewayConfig(
    configPath: "/tmp/calendar-gateway-test.toml",
    storage: CalendarStorageConfig(cacheDir: "/tmp/calendar-gateway-cache"),
    credentials: [
      CalendarCredentialConfig(
        id: "google-personal",
        provider: .google,
        accessMode: accessMode,
        oauthClientSecretPath: "/tmp/google-client.json",
        oauthClientSecretJSON: "{}",
        tokenStorePath: "/tmp/token.json",
        tokenStoreJSON: "{}"
      )
    ],
    accounts: [
      CalendarAccountConfig(
        id: "personal",
        displayName: "Personal",
        provider: .google,
        emailAddress: "person@example.com",
        credentialId: "google-personal",
        calendarIds: ["primary"],
        defaultCalendarId: "primary",
        defaultTimeZone: "UTC"
      )
    ]
  )
}
