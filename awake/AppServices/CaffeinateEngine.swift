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
            throw CaffeinateError.alreadyRunning
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")

        var args = ["-d", "-i", "-m"]
        if case let .timed(duration) = mode {
            args += ["-t", String(max(1, Int(duration.rounded(.up))))]
        }
        process.arguments = args

        process.terminationHandler = { [weak self] task in
            guard let self else { return }

            guard self.process === task else {
                return
            }
            self.process = nil

            if self.suppressedTerminationPID == task.processIdentifier {
                self.suppressedTerminationPID = nil
                return
            }

            let shouldNotify = task.terminationReason != .exit || task.terminationStatus != 0

            if shouldNotify {
                onUnexpectedStop()
            }
        }

        do {
            try process.run()
            self.process = process
            suppressedTerminationPID = nil
        } catch {
            self.process = nil
            throw CaffeinateError.failedToLaunch
        }
    }

    func stop() {
        guard let process else { return }

        suppressedTerminationPID = process.processIdentifier
        if process.isRunning {
            process.terminate()
        } else {
            self.process = nil
        }
    }
}
