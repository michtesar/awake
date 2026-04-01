import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let sessionManager = AwakeSessionManager(
        engine: CaffeinateEngine(),
        snapshotStore: UserDefaultsSnapshotStore(),
        dateProvider: SystemDateProvider()
    )

    let loginItemManager = LoginItemManager()

    private var statusBarController: StatusBarController?
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(
            sessionManager: sessionManager,
            loginItemManager: loginItemManager,
            onAboutRequested: { [weak self] in
                self?.showAboutWindow()
            }
        )

        AwakeLogger.shared.event(level: .info, component: "AppDelegate", action: "DidFinishLaunching")
        AwakeLogger.shared.event(level: .debug, component: "StatusBar", action: "ControllerInitialized")
    }

    func showAboutWindow() {
        AwakeLogger.shared.event(level: .trace, component: "About", action: "OpenRequested")
        if aboutWindow == nil {
            let host = NSHostingController(rootView: AboutAwakeView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 430),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = L10n.string("about.window.title")
            window.isReleasedWhenClosed = false
            window.center()
            window.contentViewController = host
            aboutWindow = window
            AwakeLogger.shared.event(level: .debug, component: "About", action: "WindowCreated")
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        AwakeLogger.shared.event(level: .trace, component: "About", action: "WindowShown")
    }
}
