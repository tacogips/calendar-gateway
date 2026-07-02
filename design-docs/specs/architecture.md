# Architecture

## Status

Draft

## Overview

`calendar-gateway` is a Swift Package Manager project with a calendar-domain
library target, a CLI executable target, tests, and release automation for
Homebrew.

## Targets

- `CalendarGatewayCore`: calendar config, auth status, provider adapters,
  event and free/busy operations, GraphQL-style command execution, and public
  library API
- `CalendarGatewayCLI`: command line entry point for the `calendar-gateway`
  executable
- `CalendarGatewayCoreTests`: package tests

## Release Surfaces

- Homebrew formula archives under `dist/homebrew/`
- Signed and notarized Cask DMGs under `dist/homebrew-cask/`
