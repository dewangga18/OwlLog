#if canImport(UIKit)
import Combine
import OwlLog
import UIKit

/// The lifecycle delegate for ActivityKit.
@MainActor public final class OwlActivityKitLifecycleDelegate: NSObject, UIApplicationDelegate {
    /// The cancellables for the session.
    private var cancellables: Set<AnyCancellable> = []

    /// The pending task that starts the session after dismissing existing activities.
    private var startTask: Task<Void, Never>?

    /// Used to skip the redundant `didBecomeActive`after real background pauses.
    private var isPaused = false

    override public init() {
        super.init()
    }

    /// The application delegate for ActivityKit.
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        startSession()
        return true
    }

    /// Resumes the session when the app becomes active.
    public func applicationDidBecomeActive(_ application: UIApplication) {
        // `didFinishLaunching` already started the session; only re-start after the
        // app was actually paused (background/inactive), avoiding double init at launch.
        guard isPaused else { return }
        isPaused = false
        startSession()
    }

    /// Pauses the session when the app becomes inactive, keeping the Live Activity visible.
    public func applicationWillResignActive(_ application: UIApplication) {
        pauseSession()
    }

    /// Pauses the session when the app enters background, keeping the Live Activity visible.
    public func applicationDidEnterBackground(_ application: UIApplication) {
        pauseSession()
    }

    /// Ends the Live Activity before the app terminates.
    public func applicationWillTerminate(_ application: UIApplication) {
        stopSession()
    }

    /// Starts the session.
    private func startSession() {
        if #available(iOS 16.2, *) {
            cancellables.removeAll()

            // Cancel any pending start so a task that outlives `stopSession()`
            // cannot resurrect the session after it was stopped.
            startTask?.cancel()

            startTask = Task { @MainActor in
                // Only clean up leftovers when initializing a fresh session — never when
                // resuming an already-running Live Activity from the background.
                if !OwlActivityKitSession.shared.isSessionRunning {
                    await OwlLiveActivityCleanup.dismissExisting()
                }
                guard !Task.isCancelled else { return }
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

    /// Pauses the session (keeps the Live Activity visible).
    private func pauseSession() {
        isPaused = true
        cancellables.removeAll()
        startTask?.cancel()
        startTask = nil
        if #available(iOS 16.2, *) {
            OwlActivityKitSession.shared.pause()
        }
    }

    /// Stops the session and ends the Live Activity.
    private func stopSession() {
        cancellables.removeAll()
        startTask?.cancel()
        startTask = nil
        if #available(iOS 16.2, *) {
            OwlActivityKitSession.shared.stop()
        }
    }
}

#endif
