import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastError: String?

    init() {
        isEnabled = SMAppService.mainApp.status == .enabled
        AwakeLogger.shared.event(
            level: .debug,
            component: "LoginItem",
            action: "Initialized",
            details: "isEnabled=\(isEnabled)"
        )
    }

    func setEnabled(_ enabled: Bool) {
        AwakeLogger.shared.event(
            level: .info,
            component: "LoginItem",
            action: "SetRequested",
            details: "enabled=\(enabled)"
        )
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isEnabled = enabled
            lastError = nil
            AwakeLogger.shared.event(level: .info, component: "LoginItem", action: "SetSucceeded", details: "enabled=\(enabled)")
        } catch {
            isEnabled = SMAppService.mainApp.status == .enabled
            lastError = L10n.string("error.login_item.unable_to_update")
            AwakeLogger.shared.event(
                level: .error,
                component: "LoginItem",
                action: "SetFailed",
                details: "requested=\(enabled) actual=\(isEnabled) error=\(error.localizedDescription)"
            )
        }
    }
}
