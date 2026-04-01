import SwiftUI

@main
struct AwakeApp: App {
    @AppStorage("menuBarExtraInserted") private var menuBarExtraInserted = true

    @StateObject private var sessionManager = AwakeSessionManager(
        engine: CaffeinateEngine(),
        snapshotStore: UserDefaultsSnapshotStore(),
        dateProvider: SystemDateProvider()
    )

    @StateObject private var loginItemManager = LoginItemManager()

    init() {
        UserDefaults.standard.set(true, forKey: "menuBarExtraInserted")
    }

    var body: some Scene {
        MenuBarExtra(isInserted: $menuBarExtraInserted) {
            AwakeMenuContentView(sessionManager: sessionManager, loginItemManager: loginItemManager)
        } label: {
            MenuBarLabelView(sessionManager: sessionManager)
        }
        .menuBarExtraStyle(.menu)
    }
}
