#if canImport(UIKit)
import Combine
import Foundation
import OwlLog
import UIKit
import UserNotifications

@MainActor
public final class OwlAppStateNotifier {
    public static let shared = OwlAppStateNotifier()

    private let notificationCenter: UNUserNotificationCenter
    private var cancellables: Set<AnyCancellable> = []
    private var lastCallsCount: Int = 0
    private var lastNotificationAt: Date?
    private var isMonitoring = false
    private let notificationIdentifier = "OwlLogUI.AppState"

    private init(center: UNUserNotificationCenter = .current()) {
        self.notificationCenter = center
    }

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        requestAuthorization()
        startLogObserver()
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        cancellables.removeAll()
    }

    private func startLogObserver() {
        let service = OwlService.shared
        lastCallsCount = service.calls.count

        service.$calls
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calls in
                guard let self else { return }
                self.handleCallsUpdated(calls)
            }
            .store(in: &cancellables)
    }

    private func handleCallsUpdated(_ calls: [OwlHTTPCall]) {
        let newCount = calls.count

        guard newCount > lastCallsCount else {
            lastCallsCount = newCount
            return
        }

        lastCallsCount = newCount

        // Only notify when the app isn't active; avoid foreground spam.
        guard UIApplication.shared.applicationState != .active else { return }

        // Throttle updates; we still replace the delivered notification.
        let now = Date()
        if let last = lastNotificationAt, now.timeIntervalSince(last) < 1.0 {
            return
        }
        lastNotificationAt = now

        pushNotification(calls: calls)
    }

    private func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge]
        notificationCenter.requestAuthorization(options: options) { _, _ in }
    }

    private func pushNotification(calls: [OwlHTTPCall]) {
        let content = UNMutableNotificationContent()
        content.title = "OwlLog Activity"
        if let latest = calls.last {
            content.subtitle = "\(latest.method) \(latest.endpoint)"
        } else {
            content.subtitle = "New network activity"
        }
        content.body = "Logged calls: \(calls.count). Tap to open the inspector."
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .passive
        }
        content.sound = nil
        content.threadIdentifier = notificationIdentifier
        content.categoryIdentifier = notificationIdentifier
        content.userInfo = ["owlEvent": "new_call", "owlCallsCount": calls.count]

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
