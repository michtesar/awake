# Awake Implementation Notes

## Architecture
Awake is split into two layers:

1. App layer (`awake/`)
- SwiftUI menu bar interface using `MenuBarExtra`.
- System integrations:
  - `CaffeinateEngine` for `/usr/bin/caffeinate`
  - `LoginItemManager` for launch-at-login
  - `UserDefaultsSnapshotStore` for session persistence

2. Core domain layer (`awake/CoreLogic`)
- `AwakeSessionManager`: single source of truth for session state.
- `AwakeMode`, `AwakeState`: domain model.
- `SessionSnapshot`: serializable representation for restore.
- Protocol-based dependencies (`AwakeEngine`, `DateProvider`, `SessionSnapshotStore`) for testability.

## Session Lifecycle
- Start:
  - Existing session is stopped.
  - `AwakeEngine.start` is called.
  - New `AwakeState.active` is emitted and persisted.
- Timed expiration:
  - Manager refreshes every second and auto-stops when end time is reached.
- Stop:
  - Engine is stopped.
  - State is set to inactive.
  - Snapshot is cleared.
- Restore on launch:
  - Timed session is restored with remaining duration.
  - Indefinite session is restarted.
  - Expired snapshots are dropped.

## Menu UX
- Quick Start section for all presets.
- Current Session section appears only when active.
- Preferences section contains:
  - Launch at Login
  - Remaining time in menu bar
- App section contains About and Quit.

## Menu Bar-Only Behavior
`INFOPLIST_KEY_LSUIElement = YES` is enabled in both Debug and Release target build settings.
