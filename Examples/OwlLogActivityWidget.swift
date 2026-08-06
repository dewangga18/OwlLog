// Example WidgetKit implementation for OwlLog Live Activity.
// Copy this into your app's Widget Extension target.
// Note: Live Activities require iOS 16.1+ for the widget itself and iOS 16.2+
// in the host app (the ActivityKit APIs used by OwlActivityKitSession).

import WidgetKit
import ActivityKit
import OwlLogUI
import SwiftUI

@available(iOSApplicationExtension 16.1, *)
struct OwlLogActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OwlLiveActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text("OwlLog")
                    .font(.headline)
                Text(context.state.subtitle)
                    .font(.subheadline)
                HStack(spacing: 12) {
                    Label("\(context.state.callsCount) calls", systemImage: "network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if context.state.errorsCount > 0 {
                        Label("\(context.state.errorsCount) errors", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            // Your host app must register the "owllog" URL scheme and handle this
            // URL (e.g. via onOpenURL or application(_:open:)) to open the OwlLog
            // inspector when the Live Activity is tapped.
            .widgetURL(URL(string: "owllog://open-inspector"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.subtitle)
                            .font(.subheadline)
                        HStack(spacing: 12) {
                            Label("\(context.state.callsCount)", systemImage: "network")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if context.state.errorsCount > 0 {
                                Label("\(context.state.errorsCount)", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .widgetURL(URL(string: "owllog://open-inspector"))
                }
            } compactLeading: {
                Text("🦉OwlLog")
            } compactTrailing: {
                if context.state.errorsCount > 0 {
                    Label("\(context.state.errorsCount)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Text("\(context.state.callsCount)")
                }
            } minimal: {
                if context.state.errorsCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Text("\(context.state.callsCount)")
                }
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
