import Foundation

public protocol DateProvider: Sendable {
    nonisolated var now: Date { get }
}

public struct SystemDateProvider: DateProvider {
    public init() {}

    public nonisolated var now: Date {
        Date()
    }
}
