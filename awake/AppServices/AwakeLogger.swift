import Foundation
import OSLog

final class AwakeLogger {
    enum Level: String {
        case trace = "TRACE"
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    static let shared = AwakeLogger()

    private let logger = Logger(subsystem: "com.michaeltesar.awake", category: "app")
    private let queue = DispatchQueue(label: "com.michaeltesar.awake.logger")

    let fileURL: URL

    private init() {
        fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("awake-debug.log")
        ensureLogFileExists()
    }

    func trace(_ message: String) {
        write(level: .trace, message: message)
    }

    func debug(_ message: String) {
        write(level: .debug, message: message)
    }

    func info(_ message: String) {
        write(level: .info, message: message)
    }

    func warning(_ message: String) {
        write(level: .warning, message: message)
    }

    func error(_ message: String) {
        write(level: .error, message: message)
    }

    func event(level: Level = .trace, component: String, action: String, details: String? = nil) {
        if let details, !details.isEmpty {
            write(level: level, message: "[\(component)] \(action) | \(details)")
        } else {
            write(level: level, message: "[\(component)] \(action)")
        }
    }

    private func ensureLogFileExists() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    private func write(level: Level, message: String) {
        switch level {
        case .trace, .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        }
        appendToFile(level, message)
    }

    private func appendToFile(_ level: Level, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        queue.async { [fileURL] in
            do {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                // Prevent logger recursion if file logging fails.
            }
        }
    }
}
