import Foundation

public enum AwakeState: Equatable, Sendable {
    case inactive
    case active(mode: AwakeMode, startedAt: Date, endsAt: Date?)

    public var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }

    public var endsAt: Date? {
        if case let .active(_, _, endsAt) = self {
            return endsAt
        }
        return nil
    }
}
