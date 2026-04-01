import Foundation

public protocol SessionSnapshotStore {
    func load() -> SessionSnapshot?
    func save(_ snapshot: SessionSnapshot)
    func clear()
}

public final class InMemorySessionSnapshotStore: SessionSnapshotStore {
    private var value: SessionSnapshot?

    public init(value: SessionSnapshot? = nil) {
        self.value = value
    }

    public func load() -> SessionSnapshot? {
        value
    }

    public func save(_ snapshot: SessionSnapshot) {
        value = snapshot
    }

    public func clear() {
        value = nil
    }
}
