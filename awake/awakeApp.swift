import SwiftUI

@main
struct AwakeApp: App {
    @StateObject private var sessionManager = AwakeSessionManager(
        engine: CaffeinateEngine(),
        snapshotStore: UserDefaultsSnapshotStore()
    )

    @StateObject private var loginItemManager = LoginItemManager()

    var body: some Scene {
        MenuBarExtra {
            AwakeMenuContentView(sessionManager: sessionManager, loginItemManager: loginItemManager)
        } label: {
            MenuBarLabelView(sessionManager: sessionManager)
        }
        .menuBarExtraStyle(.menu)
    }
}
