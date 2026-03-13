// Example WidgetKit implementation for OwlLog Live Activity.
// Copy this into your app's Widget Extension target.

import WidgetKit
import ActivityKit
import OwlLogUI
import SwiftUI

@available(iOSApplicationExtension 16.2, *)
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
            .widgetURL(URL(string: "owllog://open-inspector")) // your deep link
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
