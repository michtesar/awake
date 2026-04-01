import AppKit
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var sessionManager: AwakeSessionManager
    @AppStorage("showRemainingInMenuBar") private var showRemainingInMenuBar = false

    var body: some View {
        Group {
            if let remaining = visibleRemainingTime {
                HStack(spacing: 4) {
                    statusIcon
                    Text(TimeFormatting.menuBarRemaining(remaining))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
            } else {
                statusIcon
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(.easeInOut(duration: 0.16), value: sessionManager.state.isActive)
        .onAppear {
            AwakeLogger.shared.event(level: .trace, component: "MenuBarLabel", action: "Appear")
        }
        .onDisappear {
            AwakeLogger.shared.event(level: .trace, component: "MenuBarLabel", action: "Disappear")
        }
    }

    private var statusIcon: some View {
        Image(systemName: sessionManager.state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
            .symbolRenderingMode(.hierarchical)
            .imageScale(.medium)
    }

    private var visibleRemainingTime: TimeInterval? {
        guard showRemainingInMenuBar,
              let remaining = sessionManager.remainingTime(at: sessionManager.clockNow),
              remaining > 0 else {
            return nil
        }
        return remaining
    }
}

struct AwakeMenuContentView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var sessionManager: AwakeSessionManager
    @ObservedObject var loginItemManager: LoginItemManager

    @AppStorage("showRemainingInMenuBar") private var showRemainingInMenuBar = false

    var body: some View {
        Group {
            quickStartSection

            if sessionManager.state.isActive {
                Divider()
                activeSessionSection
            }

            Divider()
            preferencesSection

            if let sessionError = sessionManager.lastError {
                Divider()
                Text(sessionError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let loginError = loginItemManager.lastError {
                Text(loginError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
            appSection
        }
        .frame(minWidth: 280)
        .padding(.vertical, 2)
    }

    private var quickStartSection: some View {
        Section(L10n.string("menu.section.quick_start")) {
            Button(L10n.string("menu.quick.30m")) {
                sessionManager.start(mode: .timed(duration: 30 * 60))
            }

            Button(L10n.string("menu.quick.1h")) {
                sessionManager.start(mode: .timed(duration: 60 * 60))
            }

            Button(L10n.string("menu.quick.4h")) {
                sessionManager.start(mode: .timed(duration: 4 * 60 * 60))
            }

            Button(L10n.string("menu.quick.indefinite")) {
                sessionManager.start(mode: .indefinite)
            }
        }
    }

    private var activeSessionSection: some View {
        Section(L10n.string("menu.section.current_session")) {
            if let remaining = sessionManager.remainingTime(at: sessionManager.clockNow) {
                Text(L10n.format("menu.session.remaining", TimeFormatting.shortRemaining(remaining)))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(L10n.string("menu.session.active"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                sessionManager.stop()
            } label: {
                Text(L10n.string("menu.action.stop"))
            }
        }
    }

    private var preferencesSection: some View {
        Section(L10n.string("menu.section.preferences")) {
            Toggle(L10n.string("menu.pref.launch_at_login"), isOn: Binding(
                get: { loginItemManager.isEnabled },
                set: { loginItemManager.setEnabled($0) }
            ))

            Toggle(L10n.string("menu.pref.show_remaining_in_menubar"), isOn: $showRemainingInMenuBar)
        }
    }

    private var appSection: some View {
        Section {
            Button(L10n.string("menu.action.about")) {
                openWindow(id: "about")
            }

            Button(L10n.string("menu.action.quit")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
