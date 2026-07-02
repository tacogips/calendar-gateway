# Pending Calendar Gateway Decisions

Track user decisions that should not block the first design pass but may affect
implementation scope.

## Provider Scope

Should v1 include only Google Calendar, or should the public API include named
placeholders for additional providers?

Default design decision: implement Google Calendar first behind a generic
provider protocol.

## Write Safety

Should event create/update/delete commands expose a required dry-run mode before
live provider writes are enabled?

Default design decision: tests use fake providers, and live write operations
remain gated by explicit `read_write` access mode and OAuth scopes.

## Long-Running Transport

Is `calendar-gateway serve` required for v1, or is one-shot GraphQL sufficient?

Default design decision: one-shot GraphQL only for v1.

## CLI Shape

Should v1 remain a single `calendar-gateway` executable, or split into separate
reader/writer binaries like the mail-gateway reference?

Default design decision: use one executable with access-mode gating unless
review finds separate binaries are necessary for write safety.

## Platform Scope

Should the project preserve Linux CI for the executable now, or explicitly scope
v1 to macOS while Google Calendar OAuth bootstrap remains Apple-platform
specific?

Default design decision: v1 is macOS-only because `Package.swift` declares
macOS 14 and the current OAuth bootstrap depends on Apple platform APIs. Linux
support can be reconsidered after the OAuth bootstrap, browser launch, random
bytes, and socket receiver are behind portable adapters.
