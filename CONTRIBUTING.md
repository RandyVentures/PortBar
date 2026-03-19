# Contributing

Thanks for contributing to PortBar.

## Setup

Requirements:

- macOS 14+
- Xcode
- standard macOS command-line tools such as `lsof` and `ps`

Clone and run locally:

```bash
git clone https://github.com/RandyVentures/PortBar.git
cd PortBar
./scripts/build_app.sh
./scripts/run_app.sh
```

Open in Xcode if needed:

```bash
open PortBar.xcodeproj
```

## Development Guidelines

- Keep the architecture split clean: domain, application, infrastructure, presentation.
- Prefer small, testable changes over broad refactors.
- Keep idle CPU, memory, and battery usage low.
- Preserve the menu-bar-first UX and avoid turning the app into a full process monitor.
- Be conservative around stop-process behavior and review-risky actions carefully.

## Testing

Run the automated test suite before opening a PR:

```bash
swift test
```

Use the manual checklist for app-level verification:

- [`docs/QA_CHECKLIST.md`](docs/QA_CHECKLIST.md)

If your change affects app packaging or release flow, also review:

- [`docs/RELEASE.md`](docs/RELEASE.md)

## Pull Requests

Please keep PRs focused and include:

- a clear summary of the change
- screenshots for visible UI updates
- test coverage or manual QA notes
- any known follow-up work or tradeoffs

## Issues

When filing bugs, include:

- macOS version
- PortBar version
- expected behavior
- actual behavior
- reproduction steps

Screenshots are helpful for UI and release-install problems.
