import AppKit
import SwiftUI

struct AboutAwakeView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(spacing: 6) {
                Text("Awake")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                Text("Keep your Mac awake with zero friction.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Version \(version) (\(build))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label("Menu bar only", systemImage: "menubar.rectangle")
                Label("One-click presets", systemImage: "bolt")
                Label("Launch at login support", systemImage: "person.crop.circle.badge.checkmark")
                Label("No network, no tracking", systemImage: "lock.shield")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Button("Open Logs") {
                    NSWorkspace.shared.open(AwakeLogger.shared.fileURL)
                }

                Spacer()

                Button("Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 420)
        .background(.regularMaterial)
    }
}

#Preview {
    AboutAwakeView()
}
