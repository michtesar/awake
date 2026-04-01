import AppKit
import SwiftUI

struct AboutAwakeView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.16), radius: 8, y: 2)

                Text(L10n.string("app.name"))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))

                Text(L10n.string("about.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(L10n.format("about.version", version, build))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(systemImage: "menubar.rectangle", title: L10n.string("about.feature.menubar_only"))
                FeatureRow(systemImage: "bolt.fill", title: L10n.string("about.feature.presets"))
                FeatureRow(systemImage: "person.crop.circle.badge.checkmark", title: L10n.string("about.feature.launch_at_login"))
                FeatureRow(systemImage: "lock.shield", title: L10n.string("about.feature.privacy"))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 10) {
                Button(L10n.string("about.action.open_logs")) {
                    NSWorkspace.shared.open(AwakeLogger.shared.fileURL)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(L10n.string("about.action.close")) {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 430)
        .background(.regularMaterial)
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .center)

            Text(title)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    AboutAwakeView()
}
