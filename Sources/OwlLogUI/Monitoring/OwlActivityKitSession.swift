#if canImport(ActivityKit)
import ActivityKit
import Foundation
import OwlLog
import UIKit

/// The session for ActivityKit.
@available(iOS 16.2, *)
@MainActor public final class OwlActivityKitSession {
    /// The shared instance of the session.
    public static let shared = OwlActivityKitSession()

    /// The activity for ActivityKit.
    private var activity: Activity<OwlLiveActivityAttributes>?
    /// Whether the session is active.
    private var isActive = false
    /// The last count of calls.
    private var lastCallsCount: Int = 0
    /// The last count of errors.
    private var lastErrorsCount: Int = 0
    /// The task for monitoring the session.
    private var monitorTask: Task<Void, Never>?

    /// Starts the session.
    public func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isActive else { return }

        isActive = true
        lastCallsCount = OwlService.shared.calls.count
        lastErrorsCount = OwlService.shared.calls.filter { $0.error != nil || ($0.response?.status ?? 0) >= 400 }.count

        requestNewActivity()
        startMonitoring()
    }

    /// Requests a new activity.
    private func requestNewActivity() {
        guard activity == nil else { return }

        let attributes = OwlLiveActivityAttributes()
        let contentState = OwlLiveActivityAttributes.ContentState(
            title: "OwlLog",
            subtitle: "Waiting for traffic",
            callsCount: lastCallsCount,
            errorsCount: lastErrorsCount
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: Date().addingTimeInterval(3600)
        )

        activity = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    /// Starts monitoring the session.
    private func startMonitoring() {
        monitorTask?.cancel()

        guard let activity else { return }

        monitorTask = Task { @MainActor in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled else { break }

                switch state {
                    case .dismissed, .ended:
                        self.activity = nil

                        try? await Task.sleep(nanoseconds: 500000000)

                        guard self.isActive, !Task.isCancelled else { break }

                        self.requestNewActivity()
                        self.startMonitoring()

                    default:
                        break
                }
            }
        }
    }

    /// Stops the session.
    public func stop() {
        isActive = false
        monitorTask?.cancel()
        monitorTask = nil

        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
    }

    /// Updates the activity if needed.
    @available(iOS 16.2, *)
    public func updateIfNeeded(calls: [OwlHTTPCall]) {
        guard isActive, let activity else { return }
        let count = calls.count
        let errorsCount = calls.filter { $0.error != nil || ($0.response?.status ?? 0) >= 400 }.count
        guard count != lastCallsCount || errorsCount != lastErrorsCount else { return }
        lastCallsCount = count
        lastErrorsCount = errorsCount

        let latest = calls.last
        let contentState = OwlLiveActivityAttributes.ContentState(
            title: "OwlLog",
            subtitle: latest.map { "\($0.method) \($0.endpoint)" } ?? "New network activity",
            callsCount: count,
            errorsCount: errorsCount
        )

        let content = ActivityContent(
            state: contentState,
            staleDate: Date().addingTimeInterval(3600)
        )

        Task {
            await activity.update(content)
        }
    }
}

/// The attributes for ActivityKit.
@available(iOS 16.2, *)
public struct OwlLiveActivityAttributes: ActivityAttributes, Sendable {
    /// The content state for ActivityKit.
    public struct ContentState: Codable, Hashable, Sendable {
        public var title: String
        public var subtitle: String
        public var callsCount: Int
        public var errorsCount: Int
    }

    public init() {}
}

/// The cleanup for ActivityKit.
@available(iOS 16.2, *)
public enum OwlLiveActivityCleanup {
    /// Dismisses all existing activities.
    public static func dismissExisting() async {
        for activity in Activity<OwlLiveActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}
#else

// Fallback for iOS <16.2: no-op implementation to keep API surface stable.
public final class OwlActivityKitSession {
    public static let shared = OwlActivityKitSession()
    private init() {}
    public func start() {}
    public func stop() {}
    public func updateIfNeeded(calls: [OwlHTTPCall]) {}
    public func updateIfNeeded(calls: [OwlHTTPCall], errorsCount: Int) {}
}

#endif
