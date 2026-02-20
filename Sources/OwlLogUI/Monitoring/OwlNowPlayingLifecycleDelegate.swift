#if canImport(UIKit) && canImport(MediaPlayer) && canImport(AVFoundation)
import UIKit

public final class OwlNowPlayingLifecycleDelegate: NSObject, UIApplicationDelegate {
    override public init() {
        super.init()
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if application.applicationState == .active {
            Task { @MainActor in
                OwlNowPlayingSession.shared.start()
            }
        }
        return true
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            OwlNowPlayingSession.shared.start()
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        Task { @MainActor in
            OwlNowPlayingSession.shared.stop()
        }
    }
}

#endif
