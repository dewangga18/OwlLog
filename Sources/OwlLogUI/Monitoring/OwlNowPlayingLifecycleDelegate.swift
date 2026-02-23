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
        print("[] application", application.applicationState)
        if application.applicationState == .active {
            Task { @MainActor in
                OwlNowPlayingSession.shared.start()
            }
        }
        return true
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        print("[] applicationDidBecomeActive")
        Task { @MainActor in
            OwlNowPlayingSession.shared.start()
        }
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        print("[] applicationWillResignActive")
        Task { @MainActor in
            OwlNowPlayingSession.shared.stop()
        }
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        print("[] applicationDidEnterBackground")
        Task { @MainActor in
            OwlNowPlayingSession.shared.stop()
        }
    }
}

#endif
