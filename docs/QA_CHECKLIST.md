# PortBar QA Checklist

Target environment: macOS 14

## Setup

Before testing, have at least one local server command ready:

- `python3 -m http.server 8000`
- `npx vite --port 5173`
- `rails server -p 3000`

## Core Discovery

- Launch PortBar and open the menu bar popover.
- Verify the app loads without visible UI lag.
- Start one local server and confirm the matching port appears.
- Start a second server on a different port and confirm both ports appear.
- Verify port number, process name, PID, and address family all render.

## Search

- Search by exact port number and verify the correct row remains.
- Search by partial process name and verify filtering works.
- Search by PID and verify filtering works.
- Enter a search with no matches and verify the UI shows a distinct no-results state.
- Clear the search and verify the full list returns.

## Refresh

- Start a server while PortBar is already open and verify it does not appear until refresh.
- Press Refresh and verify the new port appears.
- Stop a server outside the app, refresh, and verify it disappears.
- Trigger refresh repeatedly and verify the button disables while refresh is active.

## Stop Action

- Stop a normal local dev server from PortBar and verify the row disappears after refresh.
- Verify the Stop button disables while the stop action is in progress.
- Attempt to stop a process you do not own, if available, and verify a clear error message appears.
- Attempt to stop a process that already exited and verify the failure is handled without crashing.

## Empty And Error States

- With no local listening ports, verify the empty state says no ports were found.
- If `lsof` fails or is unavailable in a test harness, verify the error state is visible and readable.
- Verify a refresh failure does not clear a previously loaded list if one was already shown.

## Resource Usage

- Leave PortBar idle for several minutes and verify no visible polling or UI churn occurs.
- Check Activity Monitor and verify idle CPU usage remains negligible.
- Verify memory use remains stable across repeated refreshes and stop actions.

## Regression Notes

Log these if observed:

- duplicate rows for the same PID and port
- missing IPv6 rows
- incorrect port extraction for hostname or wildcard addresses
- stale status messages after a successful refresh
