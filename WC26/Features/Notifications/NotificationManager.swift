import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    var onBanner: ((InAppBannerState) -> Void)?

    func permissionState() async -> NotificationPermissionState {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .allowed
        case .denied:
            return .denied
        case .notDetermined:
            return .notRequested
        @unknown default:
            return .notRequested
        }
    }

    func requestAuthorizationIfNeeded() async -> NotificationPermissionState {
        let currentState = await permissionState()

        guard currentState == .notRequested else {
            return currentState
        }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return await permissionState()
        }

        return await permissionState()
    }

    func deliver(
        _ event: MatchNotificationEvent,
        preferences: NotificationPreferences,
        permissionState: NotificationPermissionState
    ) {
        guard preferences.isEnabled(for: event.type) else {
            return
        }

        if preferences.showInAppBanners {
            onBanner?(InAppBannerState(event: event))
        }

        guard permissionState == .allowed else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.subtitle
        content.sound = .default
        content.interruptionLevel = .active

        let request = UNNotificationRequest(
            identifier: "wc26.\(event.matchID).\(event.type.rawValue).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request) { _ in }
    }
}
