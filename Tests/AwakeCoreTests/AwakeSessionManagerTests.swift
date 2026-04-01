import XCTest
@testable import AwakeCore

@MainActor
final class AwakeSessionManagerTests: XCTestCase {
    func testStartTimedSessionPersistsSnapshot() {
        let engine = FakeEngine()
        let now = Date(timeIntervalSince1970: 1_000)
        let dateProvider = FixedDateProvider(now: now)
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .timed(duration: 120))

        guard case let .active(mode, startedAt, endsAt) = manager.state else {
            return XCTFail("Expected active state")
        }

        XCTAssertEqual(mode, .timed(duration: 120))
        XCTAssertEqual(startedAt, now)
        XCTAssertEqual(endsAt, now.addingTimeInterval(120))
        XCTAssertEqual(store.load()?.mode, .timed)
        XCTAssertNil(manager.lastError)
    }

    func testStartIndefiniteSessionPersistsSnapshot() {
        let engine = FakeEngine()
        let now = Date(timeIntervalSince1970: 2_000)
        let dateProvider = FixedDateProvider(now: now)
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .indefinite)

        guard case let .active(mode, startedAt, endsAt) = manager.state else {
            return XCTFail("Expected active state")
        }

        XCTAssertEqual(mode, .indefinite)
        XCTAssertEqual(startedAt, now)
        XCTAssertNil(endsAt)
        XCTAssertEqual(store.load()?.mode, .indefinite)
    }

    func testStopClearsStateAndSnapshot() {
        let engine = FakeEngine()
        let dateProvider = FixedDateProvider(now: Date(timeIntervalSince1970: 2_000))
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .indefinite)
        manager.stop()

        XCTAssertEqual(manager.state, .inactive)
        XCTAssertNil(store.load())
        XCTAssertEqual(engine.stopCallCount, 2)
    }

    func testStartFailureSetsError() {
        let engine = FakeEngine(shouldThrowOnStart: true)
        let dateProvider = FixedDateProvider(now: Date(timeIntervalSince1970: 3_000))
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .timed(duration: 60))

        XCTAssertEqual(manager.state, .inactive)
        XCTAssertEqual(manager.lastError, "Unable to start Awake.")
        XCTAssertNil(store.load())
    }

    func testRefreshExpiresTimedSession() {
        let engine = FakeEngine()
        let now = Date(timeIntervalSince1970: 4_000)
        let dateProvider = MutableDateProvider(now: now)
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .timed(duration: 30))
        dateProvider.now = now.addingTimeInterval(31)
        manager.refresh()

        XCTAssertEqual(manager.state, .inactive)
        XCTAssertNil(store.load())
    }

    func testRemainingTimeIsClampedAtZero() {
        let engine = FakeEngine()
        let now = Date(timeIntervalSince1970: 5_000)
        let dateProvider = MutableDateProvider(now: now)
        let manager = AwakeSessionManager(
            engine: engine,
            snapshotStore: InMemorySessionSnapshotStore(),
            dateProvider: dateProvider,
            enableTicker: false
        )

        manager.start(mode: .timed(duration: 10))
        XCTAssertEqual(manager.remainingTime(at: now), 10)

        let afterEnd = now.addingTimeInterval(100)
        XCTAssertEqual(manager.remainingTime(at: afterEnd), 0)
    }

    func testUnexpectedStopResetsStateAndSetsError() async {
        let engine = FakeEngine()
        let dateProvider = FixedDateProvider(now: Date(timeIntervalSince1970: 6_000))
        let store = InMemorySessionSnapshotStore()
        let manager = AwakeSessionManager(engine: engine, snapshotStore: store, dateProvider: dateProvider, enableTicker: false)

        manager.start(mode: .indefinite)
        engine.triggerUnexpectedStop()

        await Task.yield()

        XCTAssertEqual(manager.state, .inactive)
        XCTAssertEqual(manager.lastError, "Awake session ended unexpectedly.")
        XCTAssertNil(store.load())
    }

    func testRestoreExpiredTimedSnapshotClearsStore() {
        let now = Date(timeIntervalSince1970: 7_000)
        let snapshot = SessionSnapshot(mode: .timed, startedAt: now.addingTimeInterval(-120), endsAt: now.addingTimeInterval(-60))
        let store = InMemorySessionSnapshotStore(value: snapshot)
        let engine = FakeEngine()

        _ = AwakeSessionManager(
            engine: engine,
            snapshotStore: store,
            dateProvider: FixedDateProvider(now: now),
            enableTicker: false
        )

        XCTAssertNil(store.load())
        XCTAssertEqual(engine.startCallCount, 0)
    }

    func testRestoreIndefiniteSnapshotRestartsEngine() {
        let now = Date(timeIntervalSince1970: 8_000)
        let snapshot = SessionSnapshot(mode: .indefinite, startedAt: now.addingTimeInterval(-120), endsAt: nil)
        let store = InMemorySessionSnapshotStore(value: snapshot)
        let engine = FakeEngine()
        let manager = AwakeSessionManager(
            engine: engine,
            snapshotStore: store,
            dateProvider: FixedDateProvider(now: now),
            enableTicker: false
        )

        XCTAssertEqual(engine.startCallCount, 1)
        XCTAssertTrue(manager.state.isActive)
    }

    func testRestoreTimedSnapshotRestartsWithRemainingDuration() {
        let now = Date(timeIntervalSince1970: 9_000)
        let endsAt = now.addingTimeInterval(90)
        let snapshot = SessionSnapshot(mode: .timed, startedAt: now.addingTimeInterval(-10), endsAt: endsAt)
        let store = InMemorySessionSnapshotStore(value: snapshot)
        let engine = FakeEngine()
        let manager = AwakeSessionManager(
            engine: engine,
            snapshotStore: store,
            dateProvider: FixedDateProvider(now: now),
            enableTicker: false
        )

        guard case let .active(mode, _, restoredEndAt) = manager.state else {
            return XCTFail("Expected restored active state")
        }

        XCTAssertEqual(engine.startCallCount, 1)
        XCTAssertEqual(mode, .timed(duration: 90))
        XCTAssertEqual(restoredEndAt, endsAt)
    }

    func testRemainingTimeForInactiveAndIndefiniteIsNil() {
        let manager = AwakeSessionManager(
            engine: FakeEngine(),
            snapshotStore: InMemorySessionSnapshotStore(),
            dateProvider: FixedDateProvider(now: Date(timeIntervalSince1970: 10_000)),
            enableTicker: false
        )

        XCTAssertNil(manager.remainingTime())

        manager.start(mode: .indefinite)
        XCTAssertNil(manager.remainingTime())
    }
}

private final class FakeEngine: AwakeEngine {
    var isRunning = false
    var shouldThrowOnStart: Bool
    var startCallCount = 0
    var stopCallCount = 0
    private var onUnexpectedStop: (@Sendable () -> Void)?

    init(shouldThrowOnStart: Bool = false) {
        self.shouldThrowOnStart = shouldThrowOnStart
    }

    func start(mode: AwakeMode, onUnexpectedStop: @escaping @Sendable () -> Void) throws {
        startCallCount += 1
        if shouldThrowOnStart {
            throw NSError(domain: "FakeEngine", code: 1)
        }
        isRunning = true
        self.onUnexpectedStop = onUnexpectedStop
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
        onUnexpectedStop = nil
    }

    func triggerUnexpectedStop() {
        isRunning = false
        onUnexpectedStop?()
    }
}

private struct FixedDateProvider: DateProvider {
    let now: Date
}

private final class MutableDateProvider: DateProvider, @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}
