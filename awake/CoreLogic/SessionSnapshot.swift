import Foundation

public struct SessionSnapshot: Codable, Equatable, Sendable {
    public enum StoredMode: String, Codable, Sendable {
        case timed
        case indefinite
    }

    public let mode: StoredMode
    public let startedAt: Date
    public let endsAt: Date?

    public init(mode: StoredMode, startedAt: Date, endsAt: Date?) {
        self.mode = mode
        self.startedAt = startedAt
        self.endsAt = endsAt
    }

    public static func from(state: AwakeState) -> SessionSnapshot? {
        switch state {
        case .inactive:
            return nil
        case let .active(mode, startedAt, endsAt):
            switch mode {
            case .timed:
                return SessionSnapshot(mode: .timed, startedAt: startedAt, endsAt: endsAt)
            case .indefinite:
                return SessionSnapshot(mode: .indefinite, startedAt: startedAt, endsAt: nil)
            }
        }
    }
}
