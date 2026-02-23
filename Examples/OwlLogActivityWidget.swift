// Example WidgetKit implementation for OwlLog Live Activity.
// Copy this into your app's Widget Extension target.

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
                Text("Calls: \(context.state.callsCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .widgetURL(URL(string: "owllog://open-inspector"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.subtitle)
                            .font(.subheadline)
                        Text("Calls: \(context.state.callsCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .widgetURL(URL(string: "owllog://open-inspector"))
                }
            } compactLeading: {
                Text("🦉OwlLog")
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
