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
    /// The in-flight task that performs the retrying initial request.
    private var startRequestTask: Task<Void, Never>?
    /// Monotonically increasing counter used to ignore stale in-flight start requests.
    private var startRequestGeneration = 0

    /// Number of attempts when requesting the initial Live Activity.
    private let startRetryAttempts = 2
    /// Delay between retry attempts.
    private let startRetryDelay: UInt64 = 500_000_000 // 0.5s

    /// Starts the session.
    public func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if isActive {
            // The activity reference may be stale if it was dismissed while the
            // app was backgrounded and monitoring was paused.
            if let activity, isActivityAlive(activity) {
                startMonitoring()
                return
            }
            self.activity = nil
        }

        isActive = true
        lastCallsCount = OwlService.shared.calls.count
        lastErrorsCount = OwlService.shared.calls.filter { $0.error != nil || ($0.response?.status ?? 0) >= 400 }.count

        startRequestTask?.cancel()
        startRequestGeneration += 1
        let generation = startRequestGeneration

        startRequestTask = Task { @MainActor in
            do {
                try await requestNewActivityWithRetry()
            } catch {
                OwlConsoleLogger.log("🦉 Live Activity: Failed to start — \(error.localizedDescription)")
                isActive = false
                clearStartRequestIfCurrent(generation)
                return
            }

            // If `stop()` was called while we were awaiting the request, end the
            // just-created activity instead of leaving an orphaned Live Activity.
            guard isActive else {
                if let activity {
                    self.activity = nil
                    Task { await activity.end(dismissalPolicy: .immediate) }
                }
                clearStartRequestIfCurrent(generation)
                return
            }

            OwlConsoleLogger.log("🦉 Live Activity started")
            startMonitoring()
            clearStartRequestIfCurrent(generation)
        }
    }

    /// Returns whether the session is active and holds a live Live Activity.
    public var isSessionRunning: Bool {
        guard isActive, let activity else { return false }
        return isActivityAlive(activity)
    }

    /// Returns whether the given activity is still shown by the system.
    private func isActivityAlive(_ activity: Activity<OwlLiveActivityAttributes>) -> Bool {
        switch activity.activityState {
            case .active, .stale:
                return true
            default:
                return false
        }
    }

    /// Clears the retained start-request task only if it is the current one.
    private func clearStartRequestIfCurrent(_ generation: Int) {
        guard startRequestGeneration == generation else { return }
        startRequestTask = nil
    }

    /// Requests a new activity, retrying a limited number of times.
    private func requestNewActivityWithRetry() async throws {
        var lastError: Error?

        for attempt in 0 ..< startRetryAttempts {
            // A cancelled task (e.g. `stopSession()` while the start task was pending) must not keep requesting new activities.
            guard !Task.isCancelled else { throw CancellationError() }

            do {
                try requestNewActivity()
                return
            } catch {
                lastError = error
                OwlConsoleLogger.log("🦉 Live Activity request failed (attempt \(attempt + 1)/\(startRetryAttempts)): \(error.localizedDescription)")

                if attempt < startRetryAttempts - 1 {
                    try? await Task.sleep(nanoseconds: startRetryDelay)
                }
            }
        }

        if let lastError { throw lastError }
    }

    /// Requests a new activity.
    private func requestNewActivity() throws {
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

        activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    /// Starts monitoring the session.
    private func startMonitoring() {
        guard let activity else { return }

        monitorTask?.cancel()
        monitorTask = Task { @MainActor in
            await monitor(activity: activity)
        }
    }

    /// Monitors the state of a single activity until it is dismissed, ended, or the task is cancelled.
    private func monitor(activity: Activity<OwlLiveActivityAttributes>) async {
        for await state in activity.activityStateUpdates {
            guard !Task.isCancelled else { break }

            switch state {
                case .dismissed:
                    self.activity = nil
                    self.monitorTask = nil
                    self.startRequestGeneration += 1
                    self.isActive = false
                    return

                case .ended:
                    self.activity = nil

                    try? await Task.sleep(nanoseconds: 500_000_000)

                    guard self.isActive, !Task.isCancelled else { return }

                    do {
                        try self.requestNewActivity()
                    } catch {
                        OwlConsoleLogger.log("🦉 Live Activity: Failed to re-request — \(error.localizedDescription)")
                        self.isActive = false
                        return
                    }

                    self.startMonitoring()
                    return

                default:
                    break
            }
        }

        monitorTask = nil
    }

    /// Pauses the session without ending the Live Activity.
    ///
    /// Used when the app moves to the background: the Live Activity keeps showing
    /// on the Lock Screen, but updates and monitoring are suspended until the app
    /// returns to the foreground (`start()` resumes monitoring).
    public func pause() {
        startRequestGeneration += 1
        startRequestTask?.cancel()
        startRequestTask = nil
        monitorTask?.cancel()
        monitorTask = nil
    }

    /// Stops the session and ends the Live Activity.
    public func stop() {
        isActive = false
        startRequestGeneration += 1
        startRequestTask?.cancel()
        startRequestTask = nil
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
    public func pause() {}
    public func stop() {}
    public var isSessionRunning: Bool { false }
    public func updateIfNeeded(calls: [OwlHTTPCall]) {}
    public func updateIfNeeded(calls: [OwlHTTPCall], errorsCount: Int) {}
}

#endif
