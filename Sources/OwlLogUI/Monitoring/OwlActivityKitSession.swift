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
    /// Monotonically increasing counter used to invalidate stale monitor loops.
    private var monitorGeneration = 0
    /// The in-flight task that performs the retrying initial request.
    private var startRequestTask: Task<Void, Never>?
    /// Monotonically increasing counter used to ignore stale in-flight start requests.
    private var startRequestGeneration = 0
    /// The in-flight task that updates the Live Activity, retained to serialize rapid updates.
    private var updateTask: Task<Void, Never>?
    /// Monotonically increasing counter used to coalesce rapid updates into the latest one.
    private var updateGeneration = 0

    /// Number of attempts when requesting the initial Live Activity.
    private let startRetryAttempts = 2
    /// Delay between retry attempts.
    private let startRetryDelay: UInt64 = 500_000_000 // 0.5s
    /// Debounce before applying an activity update, coalescing bursts within ActivityKit's budget.
    private let updateDebounceInterval: UInt64 = 500_000_000 // 0.5s

    /// How long the Live Activity stays fresh before the system marks it stale and removes it (default 5 minutes).
    public var staleDateInterval: TimeInterval = 300

    /// Starts the session.
    public func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if isActive {
            // Activity may be stale if dismissed while backgrounded and monitoring paused.
            if let activity, isActivityAlive(activity) {
                startMonitoring()
                return
            }
            self.activity = nil
            self.updateGeneration += 1
            self.updateTask?.cancel()
            self.updateTask = nil
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

            // If stop() ran during the request, end the new activity instead of leaving an orphan.
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
            // A cancelled start task must not keep requesting new activities.
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
            staleDate: Date().addingTimeInterval(staleDateInterval)
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
        spawnMonitorTask(for: activity)
    }

    /// Spawns a monitoring loop for the given activity without cancelling any
    /// existing task (safe to call from inside a loop that is about to exit).
    private func spawnMonitorTask(for activity: Activity<OwlLiveActivityAttributes>) {
        monitorGeneration += 1
        let generation = monitorGeneration

        monitorTask = Task { @MainActor in
            await monitor(activity: activity, generation: generation)
        }
    }

    /// Monitors a single activity until it is dismissed, the task is cancelled, or a
    /// newer loop supersedes it (detected via the generation counter).
    private func monitor(activity: Activity<OwlLiveActivityAttributes>, generation: Int) async {
        for await state in activity.activityStateUpdates {
            guard !Task.isCancelled, generation == self.monitorGeneration else { break }

            switch state {
                case .dismissed:
                    // Dismissal respected; resetting isActive re-arms on the next foreground start().
                    self.activity = nil
                    self.startRequestGeneration += 1
                    self.updateGeneration += 1
                    self.updateTask?.cancel()
                    self.updateTask = nil
                    self.isActive = false
                    if generation == self.monitorGeneration {
                        self.monitorTask = nil
                    }
                    return

                case .ended:
                    // Recreate only if the session still wants one; stop() already sets isActive = false.
                    self.activity = nil
                    self.updateGeneration += 1
                    self.updateTask?.cancel()
                    self.updateTask = nil

                    try? await Task.sleep(nanoseconds: 500_000_000)

                    guard self.isActive, !Task.isCancelled, generation == self.monitorGeneration else { return }

                    do {
                        try self.requestNewActivity()
                    } catch {
                        OwlConsoleLogger.log("🦉 Live Activity: Failed to re-request — \(error.localizedDescription)")
                        self.isActive = false
                        return
                    }

                    // Spawn a fresh loop for the new activity without cancelling this one.
                    guard let newActivity = self.activity else { return }
                    self.spawnMonitorTask(for: newActivity)
                    return

                default:
                    break
            }
        }

        // Only the current loop clears monitorTask, so a superseded loop can't wipe a newer one.
        if generation == self.monitorGeneration {
            monitorTask = nil
        }
    }

    /// Pauses the session without ending the Live Activity (keeps showing while backgrounded).
    public func pause() {
        startRequestGeneration += 1
        startRequestTask?.cancel()
        startRequestTask = nil
        monitorGeneration += 1
        monitorTask?.cancel()
        monitorTask = nil
        updateGeneration += 1
        updateTask?.cancel()
        updateTask = nil
    }

    /// Stops the session and ends the Live Activity.
    public func stop() {
        isActive = false
        startRequestGeneration += 1
        startRequestTask?.cancel()
        startRequestTask = nil
        monitorGeneration += 1
        monitorTask?.cancel()
        monitorTask = nil
        updateGeneration += 1
        updateTask?.cancel()
        updateTask = nil

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
            staleDate: Date().addingTimeInterval(staleDateInterval)
        )

        // Serialize updates: cancel any in-flight one so bursts coalesce into the latest content.
        updateGeneration += 1
        let generation = updateGeneration
        updateTask?.cancel()
        updateTask = Task { @MainActor in
            // Skip if superseded — a newer task already carries the latest content.
            guard !Task.isCancelled else { return }
            // Debounce so rapid bursts collapse into one update, respecting ActivityKit's budget.
            try? await Task.sleep(nanoseconds: updateDebounceInterval)
            guard !Task.isCancelled else { return }
            await activity.update(content)
            if generation == self.updateGeneration {
                self.updateTask = nil
            }
        }
    }

}

/// The attributes for ActivityKit.
@available(iOS 16.1, *)
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
@available(iOS 16.1, *)
public enum OwlLiveActivityCleanup {
    /// Dismisses all existing activities.
    public static func dismissExisting() async {
        for activity in Activity<OwlLiveActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}
#else

// No-op fallback for platforms without ActivityKit (e.g. macOS).
public final class OwlActivityKitSession {
    public static let shared = OwlActivityKitSession()
    private init() {}
    public func start() {}
    public func pause() {}
    public func stop() {}
    public var isSessionRunning: Bool { false }
    public func updateIfNeeded(calls: [OwlHTTPCall]) {}
}

#endif
