#if canImport(UIKit)
import Combine
import OwlLog
import UIKit

/// The lifecycle delegate for ActivityKit.
@MainActor public final class OwlActivityKitLifecycleDelegate: NSObject, UIApplicationDelegate {
    /// The cancellables for the session.
    private var cancellables: Set<AnyCancellable> = []
    /// Whether the session is active.
    private var isSessionActive = false
    /// The task for starting the session.
    private var startTask: Task<Void, Never>?

    override public init() {
        super.init()
    }

    /// The application delegate for ActivityKit.
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        startSession()
        return true
    }

    /// The application did become active.
    public func applicationDidBecomeActive(_ application: UIApplication) {
        startSession()
    }

    /// The application will terminate.
    public func applicationWillTerminate(_ application: UIApplication) {
        stopSession()
    }

    /// Starts the session.
    private func startSession() {
        if #available(iOS 16.2, *) {
            guard !isSessionActive else { return }
            isSessionActive = true
            cancellables.removeAll()

            startTask?.cancel()
            startTask = Task { @MainActor in
                await OwlLiveActivityCleanup.dismissExisting()
                guard self.isSessionActive else { return }
                OwlActivityKitSession.shared.start()
            }

            OwlService.shared.$calls
                .receive(on: DispatchQueue.main)
                .sink { calls in
                    Task { @MainActor in
                        OwlActivityKitSession.shared.updateIfNeeded(calls: calls)
                    }
                }
                .store(in: &cancellables)
        }
    }

    /// Stops the session.
    private func stopSession() {
        cancellables.removeAll()
        if #available(iOS 16.2, *) {
            isSessionActive = false
            startTask?.cancel()
            startTask = nil
            OwlActivityKitSession.shared.stop()
        }
    }
}

#endif
