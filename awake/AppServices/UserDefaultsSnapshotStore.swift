import Foundation

final class UserDefaultsSnapshotStore: SessionSnapshotStore {
    private let defaults: UserDefaults
    private let key = "awake.session.snapshot"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> SessionSnapshot? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(SessionSnapshot.self, from: data)
    }

    func save(_ snapshot: SessionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
