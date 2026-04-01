# Awake

Awake is a native, menu bar-only macOS app that keeps your Mac awake with a clean preset-driven experience.

## Highlights
- Menu bar-only UX (`LSUIElement=YES`), no Dock icon.
- One-click presets:
  - 30 minutes
  - 1 hour
  - 4 hours
  - Until turned off
- Native `caffeinate` integration (`/usr/bin/caffeinate`) with robust lifecycle handling.
- Launch at login toggle via `SMAppService.mainApp`.
- Session restore after app relaunch.
- Lightweight architecture with testable core domain logic.
- Localized UI:
  - English (`en`, default)
  - German (`de`)
  - Dutch (`nl`)
  - Czech (`cs`)

## Product Doc
- PRD: [docs/PRD.md](/Users/michael/Developer/awake/docs/PRD.md)
- Technical notes: [docs/IMPLEMENTATION.md](/Users/michael/Developer/awake/docs/IMPLEMENTATION.md)
- Testing and coverage: [docs/TESTING.md](/Users/michael/Developer/awake/docs/TESTING.md)

## Requirements
- Xcode 26+
- macOS 14+ for package tests
- macOS 26.2 target for the app (current Xcode project setting)

## Build and Run (App)
```bash
xcodebuild -project awake.xcodeproj -scheme awake -configuration Debug -destination 'platform=macOS' build
```

Run from Xcode for normal menu bar behavior and Login Item entitlement flow.

## Test and Coverage
```bash
swift test --enable-code-coverage
swift test --show-codecov-path
```

Current core coverage:
- `482/515 = 93.59%`

## CI (GitHub Actions)
- `CI` workflow:
  - SwiftPM tests with code coverage
  - coverage gate: minimum `90%`
  - Xcode app build on macOS runner
- `Dependency Review` workflow on pull requests

## Repository Layout
- `awake/`:
  - `awakeApp.swift`: app entry point and menu bar scene.
  - `UI/`: menu bar UI and formatting helpers.
  - `AppServices/`: live system integrations (`caffeinate`, launch at login, persistence).
  - `CoreLogic/`: domain models + session manager (covered by tests).
- `Tests/AwakeCoreTests/`: unit tests for core behavior.
- `docs/`: PRD and implementation docs.
