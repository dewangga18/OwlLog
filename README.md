# OwlLog 🦉

**OwlLog** is a lightweight and powerful iOS SDK for real-time HTTP/HTTPS network traffic monitoring directly on the device. Built entirely with modern Swift, it supports Swift 5.9+, Swift 6 Concurrency, and SwiftUI.

## 🚀 Motivation
Why use OwlLog?
- **Empower Testers & QA**: Testers no longer need to connect to external tools like Charles or Proxyman just to see API responses. All data is available directly on the mobile screen.
- **Fast Debugging**: Developers can quickly verify request/response payloads without digging through messy Xcode Console logs.
- **On-Device Inspector**: An intuitive UI makes it easy to navigate through network logs, view headers, body details, and duration statistics.

## 🛠 Installation

### Swift Package Manager (SPM)

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dewangga18/OwlLog.git", from: "1.0.0")
]
```

Or in Xcode:0
1. Go to **File** → **Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/dewangga18/OwlLog.git`
3. Select the version you want to use
4. Click **Add Package**


---

## 📡 Network Service Usage

OwlLog works as a `URLProtocol` interceptor. To ensure it doesn't run in your production environment, it's best practice to register it conditionally.

### 1. Register Interceptor (Recommended)
You should only add `OwlURLProtocol` to your `URLSessionConfiguration` if the environment is NOT production.

```swift
import OwlLog

func createURLSession() -> URLSession {
    let config = URLSessionConfiguration.default
    
    // Best Practice: Only register the interceptor in Staging or Development
    if AppEnvironment.current == .staging || AppEnvironment.current == .development {
        config.protocolClasses = [OwlURLProtocol.self] + (config.protocolClasses ?? [])
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
                .overlay {
                    // Inject overlay here
                    OwlOverlay()
                }
        }
    }
}
```

---

## 💡 Best Practice: Staging vs Production

It is highly recommended to exclude the network logger from **Production** builds for security and performance reasons. Instead of just using `#if DEBUG`, the best practice is to check your application's environment.

### 1. Environment-Based UI Visibility
If you have an environment enum in your app, use it to conditionally show the `OwlOverlay`.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay {
                    // Only show in staging or development environments
                    if AppEnvironment.current == .staging || AppEnvironment.current == .development {
                        OwlOverlay()
                    }
                }
        }
    }
}
```

### 2. Conditional Interceptor Registration
Similarly, you should only register the interceptor when running in a non-production environment.

```swift
func createSession() -> URLSession {
    let config = URLSessionConfiguration.default
    
    // Only intercept calls if the environment is NOT production
    if AppEnvironment.current != .production {
        config.protocolClasses = [OwlURLProtocol.self] + (config.protocolClasses ?? [])
    }
    
    return URLSession(configuration: config)
}
```

## 🔒 Security & Concurrency
OwlLog is built with the latest Swift standards:
- **Actors**: Uses the `OwlLogger` actor to prevent data races.
- **Sendable**: All data models conform to the `Sendable` protocol, ensuring safety in Swift 6 Strict Concurrency environments.
- **MainActor**: All UI updates are safely dispatched to the main thread.

---
Made with ❤️ for better debugging.
