import Foundation

public protocol AwakeEngine: AnyObject {
    var isRunning: Bool { get }

    func start(mode: AwakeMode, onUnexpectedStop: @escaping @Sendable () -> Void) throws
    func stop()
}
