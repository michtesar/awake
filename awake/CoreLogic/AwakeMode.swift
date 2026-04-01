import Foundation

public enum AwakeMode: Equatable, Sendable {
    case timed(duration: TimeInterval)
    case indefinite

    public var isTimed: Bool {
        if case .timed = self {
            return true
        }
        return false
    }

    public var duration: TimeInterval? {
        if case let .timed(duration) = self {
            return duration
        }
        return nil
    }
}
