import Combine
import Foundation

@MainActor
public final class AwakeSessionManager: ObservableObject {
    @Published public private(set) var state: AwakeState = .inactive
    @Published public private(set) var lastError: String?
    @Published public private(set) var clockNow: Date

    private let engine: AwakeEngine
    private let snapshotStore: SessionSnapshotStore
    private let dateProvider: DateProvider
    private var ticker: Timer?

    public init(
        engine: AwakeEngine,
        snapshotStore: SessionSnapshotStore,
        dateProvider: DateProvider,
        enableTicker: Bool = true
    ) {
        self.engine = engine
        self.snapshotStore = snapshotStore
        self.dateProvider = dateProvider
        self.clockNow = dateProvider.now

        restoreFromSnapshotIfNeeded()

        if enableTicker {
            startTicker()
        }
    }

    public func start(mode: AwakeMode) {
        AwakeLogger.shared.event(
            level: .info,
            component: "Session",
            action: "StartRequested",
            details: "mode=\(mode)"
        )
        clockNow = dateProvider.now
        let now = dateProvider.now

        stop(clearError: false)

        do {
            try engine.start(mode: mode, onUnexpectedStop: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.handleUnexpectedStop()
                }
            })

            let endsAt: Date?
            switch mode {
            case let .timed(duration):
                endsAt = now.addingTimeInterval(duration)
            case .indefinite:
                endsAt = nil
            }

            state = .active(mode: mode, startedAt: now, endsAt: endsAt)
            persistSnapshotIfNeeded()
            lastError = nil
            AwakeLogger.shared.event(
                level: .info,
                component: "Session",
                action: "Started",
                details: "endsAt=\(String(describing: endsAt))"
            )
        } catch {
            state = .inactive
            snapshotStore.clear()
            lastError = "Unable to start Awake."
            AwakeLogger.shared.event(
                level: .error,
                component: "Session",
                action: "StartFailed",
                details: "error=\(error.localizedDescription)"
            )
        }
    }

    public func stop(clearError: Bool = true) {
        AwakeLogger.shared.event(
            level: .info,
            component: "Session",
            action: "StopRequested",
            details: "clearError=\(clearError)"
        )
        engine.stop()
        state = .inactive
        snapshotStore.clear()
        if clearError {
            lastError = nil
        }
    }

    public func refresh() {
        clockNow = dateProvider.now

        guard case let .active(mode, _, endsAt) = state else {
            return
        }

        if case .timed = mode, let endsAt, clockNow >= endsAt {
            AwakeLogger.shared.event(level: .debug, component: "Session", action: "AutoStopTimedSession")
            stop(clearError: true)
        }
    }

    public func remainingTime(at date: Date? = nil) -> TimeInterval? {
        guard case .active(let mode, _, let endsAt) = state else {
            return nil
        }

        guard case .timed = mode, let endsAt else {
            return nil
        }

        let now = date ?? dateProvider.now
        return max(0, endsAt.timeIntervalSince(now))
    }

    private func restoreFromSnapshotIfNeeded() {
        guard let snapshot = snapshotStore.load() else {
            AwakeLogger.shared.event(level: .trace, component: "SessionRestore", action: "NoSnapshot")
            return
        }

        AwakeLogger.shared.event(
            level: .debug,
            component: "SessionRestore",
            action: "SnapshotFound",
            details: "mode=\(snapshot.mode.rawValue) endsAt=\(String(describing: snapshot.endsAt))"
        )

        switch snapshot.mode {
        case .indefinite:
            start(mode: .indefinite)
        case .timed:
            guard let endsAt = snapshot.endsAt else {
                AwakeLogger.shared.event(level: .warning, component: "SessionRestore", action: "InvalidTimedSnapshotMissingEnd")
                snapshotStore.clear()
                return
            }

            let remaining = endsAt.timeIntervalSince(dateProvider.now)
            guard remaining > 0 else {
                AwakeLogger.shared.event(level: .info, component: "SessionRestore", action: "ExpiredTimedSnapshotDiscarded")
                snapshotStore.clear()
                return
            }

            start(mode: .timed(duration: remaining))
        }
    }

    private func persistSnapshotIfNeeded() {
        guard let snapshot = SessionSnapshot.from(state: state) else {
            snapshotStore.clear()
            return
        }
        snapshotStore.save(snapshot)
    }

    private func handleUnexpectedStop() {
        state = .inactive
        snapshotStore.clear()
        lastError = "Awake session ended unexpectedly."
        AwakeLogger.shared.event(level: .error, component: "Session", action: "UnexpectedStop")
    }

    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.refresh()
            }
        }
    }
}
