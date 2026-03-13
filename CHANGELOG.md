# Changelog

All notable changes to the OwlLog project will be documented in this file.

## [1.0.7] - 2026-03-13

### Added
- **Live Activity error count** — Live Activity state now tracks `errorsCount` and surfaces it in widget/Live Activity UI.
- **Copy toasts** — Added toast feedback for URL, cURL, and response copy actions.

## [1.0.6] - 2026-03-11

### Added
- **Call detail swipe navigation** — Swipe left/right on Call Details to switch tabs (Headers/Response/Error).

### Changed
- **ActivityKit lifecycle safety** — Ensured Live Activity cleanup runs on the main actor and completes before starting a new session.
- **Concurrency safety** — Main-actor isolation for ActivityKit session and lifecycle delegate to prevent cross-actor state access.

### Fixed
- **UI hang risk** — Removed blocking `DispatchGroup` wait during Live Activity stop.
- **Safe area background** — Headers view now fills background even when content is short.

## [1.0.5] - 2026-02-24

### Added
- **Live Activity integration** — Added `OwlActivityKitSession` and `OwlActivityKitLifecycleDelegate` to drive a Live Activity (iOS 16.1+) that mirrors network log updates.
- **SwiftUI lifecycle guidance** — Documented recommended integration patterns in `README.md` for foreground/background handling.
- **Hidden overlay mode** — Added `OwlOverlay(isActive:)` so you can hide the floating button while keeping the inspector sheet modifier active.

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
