import Combine
import Foundation

@MainActor
public final class AwakeSessionManager: ObservableObject {
    @Published public private(set) var state: AwakeState = .inactive
    @Published public private(set) var lastError: String?

    private let engine: AwakeEngine
    private let snapshotStore: SessionSnapshotStore
    private let dateProvider: DateProvider
    private var ticker: Timer?

    public init(
        engine: AwakeEngine,
        snapshotStore: SessionSnapshotStore,
        dateProvider: DateProvider = SystemDateProvider(),
        enableTicker: Bool = true
    ) {
        self.engine = engine
        self.snapshotStore = snapshotStore
        self.dateProvider = dateProvider

        restoreFromSnapshotIfNeeded()

        if enableTicker {
            startTicker()
        }
    }

    public func start(mode: AwakeMode) {
        let now = dateProvider.now

        stop(clearError: false)

        do {
            try engine.start(mode: mode, onUnexpectedStop: { [weak self] in
                Task { @MainActor in
                    self?.handleUnexpectedStop()
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
        } catch {
            state = .inactive
            snapshotStore.clear()
            lastError = "Unable to start Awake."
        }
    }

    public func stop(clearError: Bool = true) {
        engine.stop()
        state = .inactive
        snapshotStore.clear()
        if clearError {
            lastError = nil
        }
    }

    public func refresh() {
        guard case let .active(mode, _, endsAt) = state else {
            return
        }

        if case .timed = mode, let endsAt, dateProvider.now >= endsAt {
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
            return
        }

        switch snapshot.mode {
        case .indefinite:
            start(mode: .indefinite)
        case .timed:
            guard let endsAt = snapshot.endsAt else {
                snapshotStore.clear()
                return
            }

            let remaining = endsAt.timeIntervalSince(dateProvider.now)
            guard remaining > 0 else {
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
    }

    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
}
