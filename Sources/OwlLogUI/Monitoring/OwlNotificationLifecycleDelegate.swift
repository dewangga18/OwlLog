#if canImport(UIKit)
import OwlLog
import UIKit
import UserNotifications

public struct OwlNotificationSettings: Sendable {
    public let authorizationStatus: UNAuthorizationStatus
    public let alertStyle: UNAlertStyle
    public let soundSetting: UNNotificationSetting
    public let badgeSetting: UNNotificationSetting
}

public final class OwlNotificationLifecycleDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    override public init() {
        super.init()
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Task { @MainActor in
            OwlAppStateNotifier.shared.startMonitoring()
        }
        return true
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        completionHandler()

        if actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                OwlService.shared.openInspector()
            }
        }
    }

    public func fetchNotificationSettings() async -> OwlNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: OwlNotificationSettings(
                    authorizationStatus: settings.authorizationStatus,
                    alertStyle: settings.alertStyle,
                    soundSetting: settings.soundSetting,
                    badgeSetting: settings.badgeSetting
                ))
            }
        }
    }
}

#endif
