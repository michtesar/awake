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
                Text(L10n.string("app.name"))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                Text(L10n.string("about.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(L10n.format("about.version", version, build))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Label(L10n.string("about.feature.menubar_only"), systemImage: "menubar.rectangle")
                Label(L10n.string("about.feature.presets"), systemImage: "bolt")
                Label(L10n.string("about.feature.launch_at_login"), systemImage: "person.crop.circle.badge.checkmark")
                Label(L10n.string("about.feature.privacy"), systemImage: "lock.shield")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            HStack {
                Button(L10n.string("about.action.open_logs")) {
                    NSWorkspace.shared.open(AwakeLogger.shared.fileURL)
                }

                Spacer()

                Button(L10n.string("about.action.close")) {
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
