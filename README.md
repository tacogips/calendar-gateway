# calendar-gateway

Swift library and local CLI gateway for calendar clients such as Google
Calendar.

## Development

```bash
nix develop
task build
task test
swift run calendar-gateway --help
```

The package uses Swift Package Manager with:

- Library target: `CalendarGatewayCore`
- Executable target: `CalendarGatewayCLI`
- Installed executable: `calendar-gateway`

Swift target names and type names must be valid Swift identifiers. If the project
name contains hyphens, keep `PROJECT_NAME` and `EXECUTABLE_NAME` hyphenated as
needed, but use identifier-safe values such as `CalendarGatewayCore`,
`CalendarGatewayCLI`, and `CalendarGatewayCommandResult` for Swift module/type
variables.

## CLI

```bash
calendar-gateway --help
calendar-gateway config validate
calendar-gateway auth status --credential google-personal
calendar-gateway auth login --credential google-personal --redirect-uri http://127.0.0.1:8765/oauth2callback
calendar-gateway cache prune --calendar personal
calendar-gateway graphql --query '{ calendars { id provider } }'
calendar-gateway graphql --query '{ freeBusy(calendarId: "personal", timeMin: "2026-07-01T00:00:00Z", timeMax: "2026-07-02T00:00:00Z") { calendars { id busy { start end } } } }'
calendar-gateway graphql --query '{ calendarAPI(credentialId: "google-personal", method: "GET", path: "/colors") { status body } }'
```

Configuration defaults to `$XDG_CONFIG_HOME/calendar-gateway/config.toml` and
can be overridden with `--config` or `CALENDAR_GATEWAY_CONFIG`.

`auth login` starts a local loopback OAuth callback server, opens the Google
authorization page, exchanges the callback code, and writes the token store. Use
`--redirect-uri http://127.0.0.1:<port>/<path>` to bind a fixed local callback
URI, `--open-browser false` to print the authorization URL for manual browser
use, and `--timeout-seconds <seconds>` to control how long the callback server
waits.

Typed GraphQL fields cover accounts, provider calendar discovery, free/busy,
event search/fetch, and event create/update/delete. The `calendarAPI` field is a
library and CLI escape hatch for the rest of the official Google Calendar v3
surface, including ACLs, calendar metadata, colors, settings, channels, and
watch notification endpoints. Use `access_mode = "full"` when a credential must
request the broad `https://www.googleapis.com/auth/calendar` scope.

## Homebrew Formula

Build local formula archives:

```bash
task build:homebrew -- darwin-arm64 darwin-x64
```

Render a formula after both platform archives exist:

```bash
task homebrew:formula -- 0.1.1
```

Render directly into the default sibling tap checkout:

```bash
task homebrew:tap-formula -- 0.1.1
```

Install from the tap after the formula is published:

```bash
brew tap tacogips/tap
brew install calendar-gateway
```

## Homebrew Cask

The Cask workflow builds signed, notarized, and stapled macOS DMG artifacts.
Apple signing credentials must stay local and must not be committed.

Check the build plan:

```bash
task build:homebrew-cask -- --dry-run darwin-arm64 darwin-x64
```

Build with local signing credentials:

```bash
kinko exec --env APPLE_SIGNING_IDENTITY,APPLE_ID,APPLE_PASSWORD,APPLE_TEAM_ID -- \
  task build:homebrew-cask -- darwin-arm64 darwin-x64
```

Render a Cask:

```bash
task homebrew:cask -- 0.1.1
```

For a tagged release, build, upload, and render the tap Cask:

```bash
kinko exec --env APPLE_SIGNING_IDENTITY,APPLE_ID,APPLE_PASSWORD,APPLE_TEAM_ID -- \
  task release:homebrew-cask-local -- v0.1.1
```

See `packaging/homebrew/README.md` and `.agents/skills/` for release workflows.
