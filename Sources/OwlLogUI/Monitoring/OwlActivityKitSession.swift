#if canImport(ActivityKit)
import ActivityKit
import Foundation
import OwlLog
import UIKit

@available(iOS 16.2, *)
public final class OwlActivityKitSession {
    public static let shared = OwlActivityKitSession()

    private var activity: Activity<OwlLiveActivityAttributes>?
    private var isActive = false
    private var lastCallsCount: Int = 0
    private var monitorTask: Task<Void, Never>?

    private init() {}

    @MainActor
    public func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isActive else { return }

        isActive = true
        lastCallsCount = OwlService.shared.calls.count

        requestNewActivity()
        startMonitoring()
    }

    @MainActor
    private func requestNewActivity() {
        guard activity == nil else { return }

        let attributes = OwlLiveActivityAttributes()
        let contentState = OwlLiveActivityAttributes.ContentState(
            title: "OwlLog",
            subtitle: "Waiting for traffic",
            callsCount: lastCallsCount
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

    @MainActor
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

    public func stop() {
        isActive = false
        monitorTask?.cancel()
        monitorTask = nil

        guard let activity else { return }
        self.activity = nil

        let group = DispatchGroup()
        group.enter()

        Task {
            await activity.end(dismissalPolicy: .immediate)
            group.leave()
        }

        _ = group.wait(timeout: .now() + 3)
    }

    @available(iOS 16.2, *)
    @MainActor
    public func updateIfNeeded(calls: [OwlHTTPCall]) {
        guard isActive, let activity else { return }
        let count = calls.count
        guard count != lastCallsCount else { return }
        lastCallsCount = count

        let latest = calls.last
        let contentState = OwlLiveActivityAttributes.ContentState(
            title: "OwlLog",
            subtitle: latest.map { "\($0.method) \($0.endpoint)" } ?? "New network activity",
            callsCount: count
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

@available(iOS 16.2, *)
public struct OwlLiveActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var title: String
        public var subtitle: String
        public var callsCount: Int
    }

    public init() {}
}

@available(iOS 16.2, *)
public enum OwlLiveActivityCleanup {
    public static func dismissExisting() {
        Task { @MainActor in
            for activity in Activity<OwlLiveActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
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
}

#endif

// #if canImport(ActivityKit)
// import ActivityKit
// import Foundation
// import OwlLog
// import UIKit
//
// @available(iOS 16.1, *)
// public final class OwlActivityKitSession {
//    public static let shared = OwlActivityKitSession()
//
//    private var activity: Activity<OwlLiveActivityAttributes>?
//    private var isActive = false
//    private var lastCallsCount: Int = 0
//
//    private init() {}
//
//    @MainActor
//    public func start() {
//        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
//        guard activity == nil else { return }
//
//        isActive = true
//        lastCallsCount = OwlService.shared.calls.count
//
//        let attributes = OwlLiveActivityAttributes()
//        let content = OwlLiveActivityAttributes.ContentState(
//            title: "OwlLog",
//            subtitle: "Waiting for traffic",
//            callsCount: lastCallsCount
//        )
//
//        activity = try? Activity.request(
//            attributes: attributes,
//            contentState: content,
//            pushType: nil
//        )
//    }
//
//    public func stop() {
//        isActive = false
//        Task {
//            await activity?.end(dismissalPolicy: .immediate)
//            activity = nil
//        }
//    }
//
//    @MainActor
//    public func updateIfNeeded(calls: [OwlHTTPCall]) {
//        guard isActive, let activity else { return }
//        let count = calls.count
//        guard count != lastCallsCount else { return }
//        lastCallsCount = count
//
//        let latest = calls.last
//        let content = OwlLiveActivityAttributes.ContentState(
//            title: "OwlLog",
//            subtitle: latest.map { "\($0.method) \($0.endpoint)" } ?? "New network activity",
//            callsCount: count
//        )
//
//        Task {
//            await activity.update(using: content)
//        }
//    }
//
// }
//
// @available(iOS 16.1, *)
// public struct OwlLiveActivityAttributes: ActivityAttributes, Sendable {
//    public struct ContentState: Codable, Hashable, Sendable {
//        public var title: String
//        public var subtitle: String
//        public var callsCount: Int
//    }
//
//    public init() {}
// }
//
//
// @available(iOS 16.1, *)
// public enum OwlLiveActivityCleanup {
//    public static func dismissExisting() {
//        Task { @MainActor in
//            for activity in Activity<OwlLiveActivityAttributes>.activities {
//                await activity.end(dismissalPolicy: .immediate)
//            }
//        }
//    }
// }
// #else
//
//// Fallback for iOS <16.1: no-op implementation to keep API surface stable.
// public final class OwlActivityKitSession {
//    public static let shared = OwlActivityKitSession()
//    private init() {}
//    public func start() {}
//    public func stop() {}
//    public func updateIfNeeded(calls: [OwlHTTPCall]) {}
// }
//
// #endif
