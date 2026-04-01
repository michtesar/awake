import AppKit
import Combine
import Foundation

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private enum DefaultsKeys {
        static let showRemainingInMenuBar = "showRemainingInMenuBar"
    }

    private let sessionManager: AwakeSessionManager
    private let loginItemManager: LoginItemManager
    private let onAboutRequested: () -> Void
    private let statusItem: NSStatusItem
    private var currentMenu: NSMenu?
    private var cancellables = Set<AnyCancellable>()

    init(
        sessionManager: AwakeSessionManager,
        loginItemManager: LoginItemManager,
        onAboutRequested: @escaping () -> Void
    ) {
        self.sessionManager = sessionManager
        self.loginItemManager = loginItemManager
        self.onAboutRequested = onAboutRequested
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        configureButton()
        bindState()
        updateStatusButton()
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            AwakeLogger.shared.event(level: .error, component: "StatusBar", action: "ButtonUnavailable")
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeft
        AwakeLogger.shared.event(level: .debug, component: "StatusBar", action: "ButtonConfigured")
    }

    private func bindState() {
        sessionManager.$state
            .combineLatest(sessionManager.$clockNow)
            .sink { [weak self] _, _ in
                self?.updateStatusButton()
            }
            .store(in: &cancellables)

        loginItemManager.$isEnabled
            .sink { [weak self] _ in
                self?.updateStatusButton()
            }
            .store(in: &cancellables)
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            AwakeLogger.shared.event(level: .warning, component: "StatusBar", action: "ClickWithoutCurrentEvent")
            return
        }

        switch event.type {
        case .rightMouseUp:
            AwakeLogger.shared.event(level: .trace, component: "StatusBar", action: "RightClick")
            handleRightClickQuickAction()
        case .leftMouseUp:
            AwakeLogger.shared.event(level: .trace, component: "StatusBar", action: "LeftClick")
            showMenu()
        default:
            break
        }
    }

    private func handleRightClickQuickAction() {
        switch sessionManager.state {
        case .active(let mode, _, _):
            if case .indefinite = mode {
                AwakeLogger.shared.event(level: .info, component: "StatusBar", action: "RightClickQuickStop")
                sessionManager.stop()
            } else {
                AwakeLogger.shared.event(level: .info, component: "StatusBar", action: "RightClickSwitchToIndefinite")
                sessionManager.start(mode: .indefinite)
            }
        case .inactive:
            AwakeLogger.shared.event(level: .info, component: "StatusBar", action: "RightClickStartIndefinite")
            sessionManager.start(mode: .indefinite)
        }

        updateStatusButton()
    }

    private func showMenu() {
        AwakeLogger.shared.event(level: .trace, component: "StatusBar", action: "MenuOpen")
        let menu = buildMenu()
        menu.delegate = self
        currentMenu = menu
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        addSectionHeader(L10n.string("menu.section.quick_start"), to: menu)
        menu.addItem(makeActionItem(L10n.string("menu.quick.30m"), action: #selector(start30Minutes)))
        menu.addItem(makeActionItem(L10n.string("menu.quick.1h"), action: #selector(start1Hour)))
        menu.addItem(makeActionItem(L10n.string("menu.quick.4h"), action: #selector(start4Hours)))
        menu.addItem(makeActionItem(L10n.string("menu.quick.indefinite"), action: #selector(startIndefinite)))

        if sessionManager.state.isActive {
            menu.addItem(.separator())
            addSectionHeader(L10n.string("menu.section.current_session"), to: menu)

            let remainingText: String
            if let remaining = sessionManager.remainingTime(at: sessionManager.clockNow) {
                remainingText = L10n.format("menu.session.remaining", TimeFormatting.shortRemaining(remaining))
            } else {
                remainingText = L10n.string("menu.session.active")
            }

            let statusItem = NSMenuItem(title: remainingText, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            menu.addItem(makeActionItem(L10n.string("menu.action.stop"), action: #selector(stopSession)))
        }

        menu.addItem(.separator())
        addSectionHeader(L10n.string("menu.section.preferences"), to: menu)

        let launchItem = makeActionItem(L10n.string("menu.pref.launch_at_login"), action: #selector(toggleLaunchAtLogin))
        launchItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(launchItem)

        let showRemainingItem = makeActionItem(L10n.string("menu.pref.show_remaining_in_menubar"), action: #selector(toggleShowRemainingInMenuBar))
        showRemainingItem.state = isShowingRemainingInMenuBar ? .on : .off
        menu.addItem(showRemainingItem)

        if let sessionError = sessionManager.lastError {
            let errorItem = NSMenuItem(title: localizedErrorMessage(sessionError), action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        if let loginError = loginItemManager.lastError {
            let errorItem = NSMenuItem(title: localizedErrorMessage(loginError), action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())
        menu.addItem(makeActionItem(L10n.string("menu.action.about"), action: #selector(openAbout)))
        menu.addItem(makeActionItem(L10n.string("menu.action.quit"), action: #selector(quitApp), keyEquivalent: "q"))

        return menu
    }

    private func addSectionHeader(_ title: String, to menu: NSMenu) {
        let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
    }

    private func makeActionItem(_ title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private var isShowingRemainingInMenuBar: Bool {
        UserDefaults.standard.bool(forKey: DefaultsKeys.showRemainingInMenuBar)
    }

    private func setShowRemainingInMenuBar(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: DefaultsKeys.showRemainingInMenuBar)
        AwakeLogger.shared.event(
            level: .info,
            component: "Preferences",
            action: "ShowRemainingInMenuBarChanged",
            details: "value=\(value)"
        )
        updateStatusButton()
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }

        let isActive = sessionManager.state.isActive
        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"

        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: L10n.string("app.name"))
        button.image?.isTemplate = true

        if isShowingRemainingInMenuBar,
           let remaining = sessionManager.remainingTime(at: sessionManager.clockNow),
           remaining > 0 {
            button.title = " \(TimeFormatting.menuBarRemaining(remaining))"
        } else {
            button.title = ""
        }

        button.toolTip = isActive ? L10n.string("status.tooltip.active") : L10n.string("status.tooltip.inactive")
    }

    private func localizedErrorMessage(_ message: String) -> String {
        switch message {
        case "Unable to start Awake.":
            return L10n.string("error.session.unable_to_start")
        case "Awake session ended unexpectedly.":
            return L10n.string("error.session.unexpected_stop")
        case "Unable to update Launch at Login.":
            return L10n.string("error.login_item.unable_to_update")
        default:
            return message
        }
    }

    @objc private func start30Minutes() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "Start30Minutes")
        sessionManager.start(mode: .timed(duration: 30 * 60))
    }

    @objc private func start1Hour() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "Start1Hour")
        sessionManager.start(mode: .timed(duration: 60 * 60))
    }

    @objc private func start4Hours() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "Start4Hours")
        sessionManager.start(mode: .timed(duration: 4 * 60 * 60))
    }

    @objc private func startIndefinite() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "StartIndefinite")
        sessionManager.start(mode: .indefinite)
    }

    @objc private func stopSession() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "StopSession")
        sessionManager.stop()
    }

    @objc private func toggleLaunchAtLogin() {
        loginItemManager.setEnabled(!loginItemManager.isEnabled)
    }

    @objc private func toggleShowRemainingInMenuBar() {
        setShowRemainingInMenuBar(!isShowingRemainingInMenuBar)
    }

    @objc private func openAbout() {
        AwakeLogger.shared.event(level: .trace, component: "MenuAction", action: "OpenAbout")
        onAboutRequested()
    }

    @objc private func quitApp() {
        AwakeLogger.shared.event(level: .info, component: "MenuAction", action: "Quit")
        NSApp.terminate(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        AwakeLogger.shared.event(level: .trace, component: "StatusBar", action: "MenuClosed")
        if statusItem.menu === menu {
            statusItem.menu = nil
        }
        if currentMenu === menu {
            currentMenu = nil
        }
    }
}
