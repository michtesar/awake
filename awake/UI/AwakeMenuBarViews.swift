import AppKit
import Combine
import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var sessionManager: AwakeSessionManager
    @AppStorage("showRemainingInMenuBar") private var showRemainingInMenuBar = true
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sessionManager.state.isActive ? "bolt.circle.fill" : "bolt.circle")

            if showRemainingInMenuBar,
               let remaining = sessionManager.remainingTime(at: now),
               remaining > 0 {
                Text(TimeFormatting.menuBarRemaining(remaining))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .animation(.easeInOut(duration: 0.16), value: sessionManager.state.isActive)
        .onReceive(timer) { now = $0 }
        .onAppear {
            AwakeLogger.shared.log("MenuBar label appeared")
        }
        .onDisappear {
            AwakeLogger.shared.log("MenuBar label disappeared")
        }
    }
}

struct AwakeMenuContentView: View {
    @ObservedObject var sessionManager: AwakeSessionManager
    @ObservedObject var loginItemManager: LoginItemManager

    @AppStorage("showRemainingInMenuBar") private var showRemainingInMenuBar = true

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
        Section("Quick Start") {
            Button("Keep Awake for 30 minutes") {
                sessionManager.start(mode: .timed(duration: 30 * 60))
            }

            Button("Keep Awake for 1 hour") {
                sessionManager.start(mode: .timed(duration: 60 * 60))
            }

            Button("Keep Awake for 4 hours") {
                sessionManager.start(mode: .timed(duration: 4 * 60 * 60))
            }

            Button("Keep Awake until turned off") {
                sessionManager.start(mode: .indefinite)
            }
        }
    }

    private var activeSessionSection: some View {
        Section("Current Session") {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                if let remaining = sessionManager.remainingTime(at: context.date) {
                    Text("Remaining: \(TimeFormatting.shortRemaining(remaining))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Awake is active")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                sessionManager.stop()
            } label: {
                Text("Stop")
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Launch at Login", isOn: Binding(
                get: { loginItemManager.isEnabled },
                set: { loginItemManager.setEnabled($0) }
            ))

            Toggle("Show Remaining Time in Menu Bar", isOn: $showRemainingInMenuBar)
        }
    }

    private var appSection: some View {
        Section {
            Button("Open Debug Log") {
                NSWorkspace.shared.open(AwakeLogger.shared.fileURL)
            }

            Button("About Awake") {
                NSApp.orderFrontStandardAboutPanel(options: [
                    NSApplication.AboutPanelOptionKey.applicationName: "Awake"
                ])
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
