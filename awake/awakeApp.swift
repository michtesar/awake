import SwiftUI

@main
struct AwakeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        AwakeLogger.shared.event(
            level: .info,
            component: "App",
            action: "Init",
            details: "PID=\(ProcessInfo.processInfo.processIdentifier)"
        )
        UserDefaults.standard.register(defaults: [
            "showRemainingInMenuBar": false
        ])
        AwakeLogger.shared.event(
            level: .debug,
            component: "App",
            action: "DefaultsRegistered",
            details: "showRemainingInMenuBar=false"
        )
        AwakeLogger.shared.event(
            level: .info,
            component: "Logger",
            action: "FilePath",
            details: AwakeLogger.shared.fileURL.path
        )
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
