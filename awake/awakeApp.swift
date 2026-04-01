import SwiftUI

@main
struct AwakeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("menuBarExtraInserted") private var menuBarExtraInserted = true

    @StateObject private var sessionManager = AwakeSessionManager(
        engine: CaffeinateEngine(),
        snapshotStore: UserDefaultsSnapshotStore(),
        dateProvider: SystemDateProvider()
    )

    @StateObject private var loginItemManager = LoginItemManager()

    init() {
        AwakeLogger.shared.log("App init started. PID=\(ProcessInfo.processInfo.processIdentifier)")
        let storedValue = UserDefaults.standard.object(forKey: "menuBarExtraInserted")
        AwakeLogger.shared.log("Stored menuBarExtraInserted before forcing value: \(String(describing: storedValue))")
        UserDefaults.standard.set(true, forKey: "menuBarExtraInserted")
        AwakeLogger.shared.log("menuBarExtraInserted forced to true in UserDefaults")
        AwakeLogger.shared.log("Debug log file path: \(AwakeLogger.shared.fileURL.path)")
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $menuBarExtraInserted) {
            AwakeMenuContentView(sessionManager: sessionManager, loginItemManager: loginItemManager)
        } label: {
            MenuBarLabelView(sessionManager: sessionManager)
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: menuBarExtraInserted) { inserted in
            AwakeLogger.shared.log("MenuBarExtra insertion state changed: \(inserted)")
        }
        .onChange(of: scenePhase) { phase in
            AwakeLogger.shared.log("Scene phase changed: \(String(describing: phase))")
        }
    }
}
