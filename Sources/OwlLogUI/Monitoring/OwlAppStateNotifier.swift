#if canImport(UIKit)
import Foundation
import UIKit
import UserNotifications

@MainActor
public final class OwlAppStateNotifier {
    public enum AppActivityState: String, Sendable {
        case foreground
        case background

        var description: String {
            switch self {
            case .foreground: return "foreground"
            case .background: return "background"
            }
        }
    }

    public static let shared = OwlAppStateNotifier()

    private let notificationCenter: UNUserNotificationCenter
    private var observers: [NSObjectProtocol] = []
    private var lastState: AppActivityState?
    private var isMonitoring = false
    private let notificationIdentifier = "OwlLogUI.AppState"

    private init(center: UNUserNotificationCenter = .current()) {
        self.notificationCenter = center
    }

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        requestAuthorization()
        registerObservers()
        publishCurrentState()
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        removeObservers()
    }

    private func registerObservers() {
        let center = NotificationCenter.default
        let mapping: [(NSNotification.Name, AppActivityState)] = [
            (UIApplication.didBecomeActiveNotification, .foreground),
            (UIApplication.willResignActiveNotification, .background),
            (UIApplication.didEnterBackgroundNotification, .background)
        ]

        for (name, state) in mapping {
            let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handle(state: state)
                }
            }
            observers.append(observer)
        }
    }

    private func removeObservers() {
        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }

    private func publishCurrentState() {
        guard let current = currentActivityState() else { return }
        handle(state: current)
    }

    private func currentActivityState() -> AppActivityState? {
        switch UIApplication.shared.applicationState {
        case .active:
            return .foreground
        case .inactive, .background:
            return .background
        @unknown default:
            return .foreground
        }
    }

    private func handle(state: AppActivityState) {
        guard state != lastState else { return }
        lastState = state
        pushNotification(for: state)
    }

    private func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        notificationCenter.requestAuthorization(options: options) { _, _ in }
    }

    private func pushNotification(for state: AppActivityState) {
        let content = UNMutableNotificationContent()
        content.title = "OwlLog Activity"
        content.subtitle = "App moved to the \(state.description)"
        content.body = "Tap to open the inspector and examine the latest network traffic."
        content.interruptionLevel = .timeSensitive
        content.sound = nil
        content.threadIdentifier = notificationIdentifier
        content.categoryIdentifier = notificationIdentifier
        content.userInfo = ["owlAppState": state.rawValue]

        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notificationIdentifier])
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: nil)
        notificationCenter.add(request) { error in
            #if DEBUG
            if let error = error {
                print("⚠️ OwlAppStateNotifier: failed to post notification – \(error.localizedDescription)")
            }
            #endif
        }
    }
}

#endif
