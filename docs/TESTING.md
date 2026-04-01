# Testing and Coverage

## Scope
Automated tests focus on the core domain/session layer (`awake/CoreLogic`) where deterministic behavior matters most.

## Run Tests
```bash
swift test --enable-code-coverage
```

## Locate Coverage Artifact
```bash
swift test --show-codecov-path
```

Expected path:
- `.build/arm64-apple-macosx/debug/codecov/AwakeCore.json`

## Current Coverage
Computed from the Swift coverage JSON:
- `482/515 = 93.59%`

## Covered Scenarios
- Session start for timed and indefinite modes.
- Session stop and persistence cleanup.
- Start failures and user-facing error state.
- Timed expiration through refresh logic.
- Remaining-time computation including clamping to zero.
- Unexpected process stop handling.
- Snapshot restore behavior (indefinite, timed remaining, expired snapshot cleanup).
- Domain model helper behavior and snapshot serialization mapping.

## Non-Covered Areas
- UI rendering (`SwiftUI` view composition).
- Live macOS integrations (`SMAppService`, `Process` runtime behavior of `/usr/bin/caffeinate`).

These areas are validated through build checks and manual smoke testing in Xcode.
