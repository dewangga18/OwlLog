#if canImport(UIKit)
import Combine
import OwlLog
import UIKit

public final class OwlActivityKitLifecycleDelegate: NSObject, UIApplicationDelegate {
    private var cancellables: Set<AnyCancellable> = []

    override public init() {
        super.init()
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        startSession()
        return true
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        startSession()
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        stopSession()
    }

    private func startSession() {
        if #available(iOS 16.2, *) {
            cancellables.removeAll()

            Task { @MainActor in
                OwlLiveActivityCleanup.dismissExisting()
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

    private func stopSession() {
        cancellables.removeAll()
        if #available(iOS 16.2, *) {
            OwlActivityKitSession.shared.stop()
        }
    }
}

#endif
