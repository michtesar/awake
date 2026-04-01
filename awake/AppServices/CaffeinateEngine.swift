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
    private var onUnexpectedStop: (@Sendable () -> Void)?

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

        self.onUnexpectedStop = onUnexpectedStop

        process.terminationHandler = { [weak self] task in
            guard let self else { return }

            let shouldNotify = task.terminationReason != .exit || task.terminationStatus != 0
            self.process = nil

            if shouldNotify {
                self.onUnexpectedStop?()
            }
        }

        do {
            try process.run()
            self.process = process
        } catch {
            self.process = nil
            self.onUnexpectedStop = nil
            throw CaffeinateError.failedToLaunch
        }
    }

    func stop() {
        onUnexpectedStop = nil
        guard let process else { return }

        if process.isRunning {
            process.terminate()
        }
        self.process = nil
    }
}
