# Command

## Status

Draft

## Current CLI

```bash
calendar-gateway [--config <path>] [--pretty] <command>
```

Implemented commands:

- `calendar-gateway --help`
- `calendar-gateway help`
- `calendar-gateway --version`
- `calendar-gateway config validate`
- `calendar-gateway auth status --credential <id>`
- `calendar-gateway auth revoke --credential <id>`
- `calendar-gateway auth login --credential <id>`
- `calendar-gateway cache prune --calendar <id>`
- `calendar-gateway cache prune --all`
- `calendar-gateway graphql --query <query> [--variables <json>|--variables-file <path>]`
- `calendar-gateway graphql --query-file <path> [--variables <json>|--variables-file <path>]`

The CLI writes business payloads as JSON on stdout and structured errors as
JSON on stderr. `auth login` runs Google installed-app OAuth for desktop client
JSON. Token stores can also be supplied through the config file or
`CALENDAR_GATEWAY_CREDENTIAL_<ID>_TOKEN_STORE_JSON`.
Unknown flags are rejected with `INVALID_ARGUMENT` and exit code 2 before
loading config or contacting providers.
Unexpected positional arguments are rejected the same way, before config loading
or side effects.
Global `--help` and `--version` reject unknown flags and reject attached values
such as `--version=false` before returning success output.
Duplicate flags are rejected before config loading, provider calls, or global
success output; callers must supply each flag at most once.
Variable JSON is parsed and validated as an object for CLI compatibility with
the mail-gateway transport contract; the current lightweight GraphQL parser
still uses flat literal arguments. Until variable substitution is implemented,
queries that reference GraphQL variables with `$name` must fail with
`INVALID_ARGUMENT` instead of silently ignoring supplied variables.

Exit codes:

| Code | Meaning |
|------|---------|
| 0 | success |
| 1 | unexpected failure |
| 2 | invalid CLI usage or invalid argument |
| 3 | configuration or credential error |
| 4 | authentication required |
| 5 | GraphQL execution or provider API failure |
| 6 | write operation disabled by configured access mode |

Implemented GraphQL-style root fields:

- `calendars`
- `calendar(id: "...")`
- `providerCalendars(credentialId: "...")`
- `freeBusy(calendarId: "...", providerCalendarIds: ["..."], timeMin: "...", timeMax: "...")`
- `events(calendarId: "...", providerCalendarId: "...", timeMin: "...", timeMax: "...", updatedMin: "...", cursor: "...")`
- `events(calendarId: "...", syncToken: "...", showDeleted: true, singleEvents: false)`
- `event(calendarId: "...", providerCalendarId: "...", eventId: "...")`
- `createEvent(calendarId: "...", summary: "...", start: "...", end: "...", recurrenceRules: ["RRULE:..."], colorId: "7", createConference: true)`
- `updateEvent(calendarId: "...", eventId: "...", summary: "...", reminderOverrides: ["popup:30"], visibility: "private", transparency: "transparent")`
- `deleteEvent(calendarId: "...", eventId: "...", sendUpdates: "all|externalOnly|none")`
- `calendarAPI(credentialId: "...", method: "GET|POST|PUT|PATCH|DELETE", path: "/colors", query: ["name=value"], body: "{\"json\":true}", access: "auto|read|write")`

The lightweight GraphQL executor accepts exactly one top-level root field per
operation. A document containing multiple root fields must fail with
`INVALID_ARGUMENT`; silent partial results are not allowed. Resolver dispatch is
based on the root field name, and write resolver names remain write-gated even
if a caller labels the operation as `query`.

Write fields fail with `WRITE_DISABLED` before provider mutation when the
credential is not configured with `access_mode = "read_write"` or
`access_mode = "full"`.
When supplied, `sendUpdates` is validated before provider mutation and must be
`all`, `externalOnly`, or `none`.

`freeBusy` returns canonical busy intervals without event details. `timeMin` and
`timeMax` are required RFC 3339 date-time strings. The accepted form includes
timestamps with or without fractional seconds and with either `Z` or an explicit
numeric offset. When no
`providerCalendarId` or `providerCalendarIds` argument is supplied, the
configured default provider calendar ID is used.

`events` supports initial and incremental sync flows. `updatedMin`, `timeMin`,
and `timeMax` must be RFC 3339 date-time strings, including Google-emitted
fractional-second values such as `.000Z`. `syncToken` accepts the
`nextSyncToken` from a completed previous event listing and cannot be combined
with `query`, `timeMin`, `timeMax`, `updatedMin`, or `orderBy`; `showDeleted:
false` is also rejected with `syncToken`.

Event mutations support recurrence and reminders. `recurrenceRules` accepts
Google-compatible RRULE/RDATE/EXRULE/EXDATE strings; `DTSTART` and `DTEND` are
rejected because event start/end are supplied separately. Reminder overrides use
flat literals in the form `popup:<minutes>` or `email:<minutes>` and support up
to 5 overrides with minutes between 0 and 40320.

Event mutations also support provider event metadata and Google Meet creation.
`colorId` must be non-empty when supplied. `visibility` accepts `default`,
`public`, `private`, or `confidential`; `transparency` accepts `opaque` or
`transparent`. `createConference: true` requests a Google Meet link on Google
Calendar writes, and `conferenceRequestId` may be supplied with
`createConference: true` as a non-empty idempotency key.

`calendarAPI` is the raw official Google Calendar v3 resolver for less common
resources such as ACLs, calendar metadata, colors, settings, channels, and watch
notification endpoints. `path` must be a relative Calendar v3 path starting with
`/`; absolute URLs and embedded query strings are rejected. Broad API usage
should use `access_mode = "full"` so OAuth requests the full Calendar scope.
Mutating HTTP methods (`POST`, `PUT`, `PATCH`, and `DELETE`) are always
write-gated before provider calls. The `access` argument is only a token-scope
hint and cannot downgrade a mutating method into a read operation.

GraphQL resolver failures should be returned through the GraphQL `errors` array
with machine-readable `extensions.code` and any safe diagnostic details. CLI
usage failures that occur before GraphQL execution may still be reported as
top-level stderr errors.
