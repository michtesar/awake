import Foundation

final class CaffeinateEngine: AwakeEngine {
    enum CaffeinateError: Error {
        case alreadyRunning
        case failedToLaunch
    }

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    private var process: Process?
    private var suppressedTerminationPID: pid_t?

    func start(mode: AwakeMode, onUnexpectedStop: @escaping @Sendable () -> Void) throws {
        if isRunning {
            AwakeLogger.shared.event(level: .warning, component: "Caffeinate", action: "StartRejectedAlreadyRunning")
            throw CaffeinateError.alreadyRunning
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")

        var args = ["-d", "-i", "-m"]
        if case let .timed(duration) = mode {
            args += ["-t", String(max(1, Int(duration.rounded(.up))))]
        }
        process.arguments = args
        AwakeLogger.shared.event(
            level: .debug,
            component: "Caffeinate",
            action: "StartProcess",
            details: "arguments=\(args.joined(separator: " "))"
        )

        process.terminationHandler = { [weak self] task in
            guard let self else { return }

            guard self.process === task else {
                AwakeLogger.shared.event(level: .trace, component: "Caffeinate", action: "IgnoreTerminationForStaleProcess")
                return
            }
            self.process = nil

            if self.suppressedTerminationPID == task.processIdentifier {
                self.suppressedTerminationPID = nil
                AwakeLogger.shared.event(
                    level: .trace,
                    component: "Caffeinate",
                    action: "TerminationSuppressed",
                    details: "pid=\(task.processIdentifier)"
                )
                return
            }

            let shouldNotify = task.terminationReason != .exit || task.terminationStatus != 0

            if shouldNotify {
                AwakeLogger.shared.event(
                    level: .error,
                    component: "Caffeinate",
                    action: "UnexpectedTermination",
                    details: "pid=\(task.processIdentifier) reason=\(task.terminationReason.rawValue) status=\(task.terminationStatus)"
                )
                onUnexpectedStop()
            } else {
                AwakeLogger.shared.event(
                    level: .info,
                    component: "Caffeinate",
                    action: "ProcessExited",
                    details: "pid=\(task.processIdentifier)"
                )
            }
        }

        do {
            try process.run()
            self.process = process
            suppressedTerminationPID = nil
            AwakeLogger.shared.event(level: .info, component: "Caffeinate", action: "ProcessStarted", details: "pid=\(process.processIdentifier)")
        } catch {
            self.process = nil
            AwakeLogger.shared.event(level: .error, component: "Caffeinate", action: "LaunchFailed", details: error.localizedDescription)
            throw CaffeinateError.failedToLaunch
        }
    }

    func stop() {
        guard let process else { return }

        suppressedTerminationPID = process.processIdentifier
        if process.isRunning {
            AwakeLogger.shared.event(level: .debug, component: "Caffeinate", action: "StopRequested", details: "pid=\(process.processIdentifier)")
            process.terminate()
        } else {
            self.process = nil
            AwakeLogger.shared.event(level: .trace, component: "Caffeinate", action: "StopNoopProcessNotRunning")
        }
    }
}
