<img width="6005" height="5957" alt="Image" src="https://github.com/user-attachments/assets/3e5348cc-7636-4759-a5db-812dbf0d48d0" /> <br>
# OwlLog 🦉

**OwlLog** is a lightweight and powerful iOS SDK for real-time HTTP/HTTPS network traffic monitoring directly on the device. Built entirely with modern Swift, it supports Swift 5.9+, Swift 6 Concurrency, and SwiftUI.

## 🚀 Motivation
Why use OwlLog?
- **Empower Testers & QA**: Testers no longer need to connect to external tools like Charles or Proxyman just to see API responses. All data is available directly on the mobile screen.
- **Fast Debugging**: Developers can quickly verify request/response payloads without digging through messy Xcode Console logs.
- **On-Device Inspector**: An intuitive UI makes it easy to navigate through network logs, view headers, body details, and duration statistics.

## 🛠 Installation

### Swift Package Manager (SPM)

Add the package to your project and choose the target that fits your needs:

| Target | Description | Recommended For |
| :--- | :--- | :--- |
| **`OwlLog`** | **Core Only**. Logic-only interceptor. Logs directly to Xcode Console. | Console-only debugging. |
| **`OwlLogUI`** | **Full Package**. Includes the core logic + Floating Visualizer Overlay. | QA, Manual Testing, and UI-based debugging. |

> **Note**: `OwlLogUI` automatically exports `OwlLog`. If you use the UI package, you don't need to import `OwlLog` separately.

<br>

**Package.swift Integration:**
```swift
dependencies: [
    .package(url: "https://github.com/dewangga18/OwlLog.git", from: "1.0.5")
]
```

**Target Dependencies:**
```swift
.target(
    name: "MyAppTarget",
    dependencies: [
        // Use "OwlLog", if you don't need the UI
        .product(name: "OwlLogUI", package: "OwlLog")
    ]
)
```

---

Or in Xcode:
1. Go to **File** → **Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/dewangga18/OwlLog.git`
3. Select the version you want to use
4. Click **Add Package**

<br>

## 📡 Network Service Usage

OwlLog works as a `URLProtocol` interceptor. To ensure it doesn't run in your production environment, it's best practice to register it conditionally.

### 1. Register Interceptor (Recommended)
You should only add `OwlURLProtocol` to your `URLSessionConfiguration` if the environment is NOT production.

```swift
import OwlLog

func createURLSession() -> URLSession {
    let config = URLSessionConfiguration.default
    
    // Best Practice: Only register the interceptor in non-production environment
    if AppEnvironment.current != .production {
        // Enable console logging, default is true
        OwlURLProtocol.setup(in: config, isConsoleLogEnabled: true) 
    }
    
    return URLSession(configuration: config)
}
```


---

## 🖥 UI Integration (Overlay)

OwlLog provides a floating "Ladybug" button overlay that stays on top of your application.

### Adding to Root View
Simply add `.overlay(OwlOverlay())` to your app's main view (usually in your `App` or `ContentView` file).

```swift
import SwiftUI
import OwlLogUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject overlay here
                .overlay {
                    // Best Practice: Only show in non-production environment
                    if AppEnvironment.current != .production {
                        OwlOverlay()
                    }
                }
        }
    }
}
```

---

You can customize the appearance of the floating button by passing parameters to the initializer:

```swift
OwlOverlay(
    backgroundColor: .blue,
    icon: Image(systemName: "ant.fill")
)
```

## 🖥 UI Integration (Live Activity)

> Live Activities require iOS 16.2+. On earlier versions, the APIs are no-ops safely.

Setup checklist:
- Runtime: iOS 16.2+ for Live Activities (package itself supports iOS 15+, calls no-op below 16.2).
- Host app target: add **Live Activities** capability (adds `NSSupportsLiveActivities=YES` to Info.plist).
- Widget target: include an `ActivityConfiguration` for `OwlLiveActivityAttributes` (see step 2).
- Deep link: register the same URL scheme used in `.widgetURL` (e.g. `owllog://open-inspector`) under URL Types, and handle it in `onOpenURL` to open the inspector.
- Behavior: tapping the Live Activity opens your app; Play/Toggle maps to `OwlService.shared.openInspector()` and Pause closes it on supported devices.

### 1. Install the Owl Delegate

```swift
@main
struct MyApp: App {
@UIApplicationDelegateAdaptor(OwlActivityKitLifecycleDelegate.self)
    private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay {
                    if AppEnvironment.current != .production {
                        OwlOverlay(isVisible: false)
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "owllog" else { return }
                    guard url.host == "open-inspector" else { return }
                    
                    Task { @MainActor in
                        OwlService.shared.openInspector()
                    }
                }
        }
    }
}
```

### 2. Add the WidgetKit target (required for UI)

Create a Widget Extension in your app, then add:

```swift
import WidgetKit
import ActivityKit
import SwiftUI
import OwlLogUI

struct OwlLogActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OwlLiveActivityAttributes.self) { context in
            // Lock Screen view
            VStack(alignment: .leading, spacing: 4) {
                Text("OwlLog")
                    .font(.headline)
                Text(context.state.subtitle)
                    .font(.subheadline)
                Text("Calls: \(context.state.callsCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .widgetURL(URL(string: "owllog://open-inspector")) // your deep link
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text(context.state.subtitle)
                            .font(.subheadline)
                        Text("Calls: \(context.state.callsCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Text("🦉")
            } compactTrailing: {
                Text("\(context.state.callsCount)")
            } minimal: {
                Text("\(context.state.callsCount)")
            }
        }
    }
}

@main
struct OwlLogActivityBundle: WidgetBundle {
    var body: some Widget {
        OwlLogActivityWidget()
    }
}
```

> Shortcut: we ship a template at `Examples/OwlLogActivityWidget.swift`. Copy that file into your Widget Extension target and adjust visuals as needed.

### 3. Customize (Optional)

If you prefer manual control, call:

```swift
Task { @MainActor in
    OwlActivityKitSession.shared.start()
    // ...
    OwlActivityKitSession.shared.stop()
}
```

OwlLog is built with the latest Swift standards:
- **Actors**: Uses the `OwlLogger` actor to prevent data races.
- **Sendable**: All data models conform to the `Sendable` protocol, ensuring safety in Swift 6 Strict Concurrency environments.
- **MainActor**: All UI updates are safely dispatched to the main thread.

---
Crafted with ☕ and ❤️ for smoother debugging.
