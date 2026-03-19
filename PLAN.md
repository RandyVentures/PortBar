# PortBar Build Plan

**Product:** Native macOS menu bar app for viewing and stopping listening local ports  
**Primary user:** A developer on their own machine  
**Current state:** Clean build, core tests passing, first UI scaffold in place

## Engineering Principles

We are optimizing for:

- clean architecture
- clean code and small, focused units
- TDD for core logic
- BDD-style acceptance language in tests and QA
- fast QA cycles
- low idle CPU, memory, and battery usage

## Architecture Shape

### `PortBarCore`

Contains the behavior that should be testable without SwiftUI:

- domain entity: `ListeningPort`
- use cases: `LoadListeningPortsUseCase`, `StopProcessUseCase`
- abstractions: `PortDiscoveryProviding`, `ProcessControlling`
- adapters: `LsofPortDiscoveryProvider`, `LsofOutputParser`, `POSIXProcessController`

### `PortBar`

Contains the UI shell only:

- `PortBarApp`
- `PortListViewModel`
- SwiftUI views for the menu bar popover

## Current Decisions

### Stop flow

Use a safe default:

1. send terminate
2. wait briefly for exit
3. escalate to force kill only if needed

### Resource usage

Keep the app cheap while idle:

- no auto-refresh in v1
- no retained history
- no background watchers
- no hidden polling timers

### QA strategy

Validate behavior in layers:

1. parser tests
2. use-case tests
3. manual UI QA on a real machine

## Completed So Far

- package scaffold with separate core and app targets
- first menu bar UI scaffold
- `lsof` discovery adapter
- POSIX process-control adapter
- tests for parser, sorting, and stop escalation behavior
- successful `swift build`
- successful `swift test`

## Next Build Slice

### 1. Improve parser coverage

Add tests for:

- malformed rows
- duplicate PID/port rows
- IPv4 and IPv6 variations
- hostname and wildcard address formats

### 2. Tighten UI state handling

Add or refine:

- clearer inline error copy
- disabled states during refresh and stop operations
- empty state copy for filtered versus truly empty results

### 3. Add QA checklist

Create a short repeatable checklist for:

- Node/Vite server
- Rails/Python server
- refresh behavior
- permission failures
- stop success and forced-stop fallback

### 4. Verify runtime behavior on a real machine

Check:

- launch behavior
- menu bar responsiveness
- no unexpected dock presence if we want menu-bar-only behavior
- no measurable idle CPU churn

## Risks

### `lsof` output variance

Mitigation:

- keep parsing conservative
- ignore malformed rows
- expand fixture coverage before adding more features

### Permission failures

Mitigation:

- return explicit user-facing failures
- never claim success if the process still exists

### Architecture drift

Mitigation:

- keep process and parser logic out of SwiftUI views
- add tests before expanding behavior

## Working Agreement For The Next Steps

Before adding convenience features, keep shipping in this order:

1. tests for the behavior
2. core implementation
3. UI wiring
4. manual QA pass
