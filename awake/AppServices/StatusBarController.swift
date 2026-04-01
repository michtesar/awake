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
            AwakeLogger.shared.error("Failed to configure status item button")
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeft
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
            return
        }

        switch event.type {
        case .rightMouseUp:
            handleRightClickQuickAction()
        case .leftMouseUp:
            showMenu()
        default:
            break
        }
    }

    private func handleRightClickQuickAction() {
        switch sessionManager.state {
        case .active(let mode, _, _):
            if case .indefinite = mode {
                sessionManager.stop()
            } else {
                sessionManager.start(mode: .indefinite)
            }
        case .inactive:
            sessionManager.start(mode: .indefinite)
        }

        updateStatusButton()
    }

    private func showMenu() {
        let menu = buildMenu()
        menu.delegate = self
        currentMenu = menu
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        addSectionHeader("Quick Start", to: menu)
        menu.addItem(makeActionItem("Keep Awake for 30 minutes", action: #selector(start30Minutes)))
        menu.addItem(makeActionItem("Keep Awake for 1 hour", action: #selector(start1Hour)))
        menu.addItem(makeActionItem("Keep Awake for 4 hours", action: #selector(start4Hours)))
        menu.addItem(makeActionItem("Keep Awake until turned off", action: #selector(startIndefinite)))

        if sessionManager.state.isActive {
            menu.addItem(.separator())
            addSectionHeader("Current Session", to: menu)

            let remainingText: String
            if let remaining = sessionManager.remainingTime(at: sessionManager.clockNow) {
                remainingText = "Remaining: \(TimeFormatting.shortRemaining(remaining))"
            } else {
                remainingText = "Awake is active"
            }

            let statusItem = NSMenuItem(title: remainingText, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
            menu.addItem(makeActionItem("Stop", action: #selector(stopSession)))
        }

        menu.addItem(.separator())
        addSectionHeader("Preferences", to: menu)

        let launchItem = makeActionItem("Launch at Login", action: #selector(toggleLaunchAtLogin))
        launchItem.state = loginItemManager.isEnabled ? .on : .off
        menu.addItem(launchItem)

        let showRemainingItem = makeActionItem("Show Remaining Time in Menu Bar", action: #selector(toggleShowRemainingInMenuBar))
        showRemainingItem.state = isShowingRemainingInMenuBar ? .on : .off
        menu.addItem(showRemainingItem)

        if let sessionError = sessionManager.lastError {
            let errorItem = NSMenuItem(title: sessionError, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        if let loginError = loginItemManager.lastError {
            let errorItem = NSMenuItem(title: loginError, action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(.separator())
        menu.addItem(makeActionItem("About Awake", action: #selector(openAbout)))
        menu.addItem(makeActionItem("Quit", action: #selector(quitApp), keyEquivalent: "q"))

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
        updateStatusButton()
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }

        let isActive = sessionManager.state.isActive
        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"

        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Awake")
        button.image?.isTemplate = true

        if isShowingRemainingInMenuBar,
           let remaining = sessionManager.remainingTime(at: sessionManager.clockNow),
           remaining > 0 {
            button.title = " \(TimeFormatting.menuBarRemaining(remaining))"
        } else {
            button.title = ""
        }

        button.toolTip = isActive ? "Awake is active" : "Awake is inactive"
    }

    @objc private func start30Minutes() {
        sessionManager.start(mode: .timed(duration: 30 * 60))
    }

    @objc private func start1Hour() {
        sessionManager.start(mode: .timed(duration: 60 * 60))
    }

    @objc private func start4Hours() {
        sessionManager.start(mode: .timed(duration: 4 * 60 * 60))
    }

    @objc private func startIndefinite() {
        sessionManager.start(mode: .indefinite)
    }

    @objc private func stopSession() {
        sessionManager.stop()
    }

    @objc private func toggleLaunchAtLogin() {
        loginItemManager.setEnabled(!loginItemManager.isEnabled)
    }

    @objc private func toggleShowRemainingInMenuBar() {
        setShowRemainingInMenuBar(!isShowingRemainingInMenuBar)
    }

    @objc private func openAbout() {
        onAboutRequested()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        if statusItem.menu === menu {
            statusItem.menu = nil
        }
        if currentMenu === menu {
            currentMenu = nil
        }
    }
}
