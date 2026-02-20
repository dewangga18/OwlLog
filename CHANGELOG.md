# Changelog

All notable changes to the OwlLog project will be documented in this file.

## [1.0.5] - 2026-02-20

### Added
- **Activity notifications** — Introduced `OwlAppStateNotifier` to observe app lifecycle changes and emit a persistent activity notification that can reopen the inspector when tapped.
- **Lifecycle delegate integration** — Added `OwlAppLifecycleDelegate` so SwiftUI hosts can attach `@UIApplicationDelegateAdaptor` and automatically configure notification delegation and state observation.
- **Notification settings helper** — Exposed `fetchNotificationSettings()` as an async, Sendable-safe snapshot to allow clients to present custom rationale screens before requesting permissions.
- **Control Center integration** — Added `OwlNowPlayingSession` and `OwlNowPlayingLifecycleDelegate` to display a Now Playing card while the app is active, mapping remote commands to reopening the inspector.
- **SwiftUI lifecycle guidance** — Documented recommended integration patterns in `README.md` for foreground/background handling.

## [1.0.4] - 2026-02-12

### Added
- **Detailed Error Reporting**: Now captures and displays stack traces and specific error codes for failed requests.
- **Network Error Classification**: Automatically categorizes errors (e.g., Offline, Timeout, DNS Failure) for easier diagnosis.
- **Console Logging**: Enhanced logging output with clear error reasons and status indicators.
- **UI Improvements**: Better text selection in error views and visual indication of error codes in the log list.
- **Status Handling**: Improved handling of missing status codes and readable HTTP status display.

## [1.0.3] - 2026-02-12

### Fix
- Fixed an issue where `OwlHTTPCall` could contain duplicated IDs, causing inconsistencies in the HTTP call list.

## [1.0.2] - 2026-02-12

### Added
- **Exported Imports**: Added `@_exported import OwlLog` in `OwlLogUI`. Users now only need to `import OwlLogUI` to access both core interceptor and UI features.
- **Multi-Platform Refinement**: Optimized build configuration to support **iOS** and **macOS** across Swift versions 5.10, 6.0, 6.1, and 6.2.
- **Unified Clipboard & UI**: Integrated cross-platform clipboard handling and navigation patterns for better consistency between iOS and macOS.

### Changed
- **Documentation Overhaul**: Updated `README.md` with a target selection guide (Core vs. Full Package) and simplified integration steps.
- **Code Quality**: Improved code organization using `MARK` comments and refined platform-specific UI adaptive logic.

## [1.0.1] - 2026-02-12

### Added
- **Simplified Setup**: Added `OwlURLProtocol.setup(in:isConsoleLogEnabled:)` to streamline interceptor registration and console logging configuration.
- **Integrated Console Logging**: Added real-time network activity logging to the Xcode console with status indicators (🚀, ✅, ⚠️, ❌).

### Changed
- **Improved Documentation**: Updated README with more concise environment-based integration examples.

## [1.0.0] - 2026-02-11

### Added
- HTTP call search & filtering
- HTTP request replay feature
- Copy as cURL support
- Statistics overview with cached calculations
- Automatic JSON/XML response formatting
- Sorted request & response headers
- Error and stack trace display
- Draggable debug overlay
