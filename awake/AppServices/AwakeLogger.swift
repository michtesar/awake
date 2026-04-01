import Foundation
import OSLog

final class AwakeLogger {
    static let shared = AwakeLogger()

    private let logger = Logger(subsystem: "com.michaeltesar.awake", category: "app")
    private let queue = DispatchQueue(label: "com.michaeltesar.awake.logger")

    let fileURL: URL

    private init() {
        fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("awake-debug.log")
        ensureLogFileExists()
    }

    func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        appendToFile("NOTICE", message)
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        appendToFile("ERROR", message)
    }

    private func ensureLogFileExists() {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    private func appendToFile(_ level: String, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"
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
