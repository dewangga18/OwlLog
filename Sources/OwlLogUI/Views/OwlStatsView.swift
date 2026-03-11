//
//  OwlStatsView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// View responsible for displaying statistics derived from captured HTTP calls.
public struct OwlStatsView: View {
    /// Service that provides the logged calls and computed statistics.
    @ObservedObject var service: OwlService

    public init(service: OwlService) {
        self.service = service
    }

    /// Root container that decides whether to show the statistics content or an empty state when no network calls are recorded.
    public var body: some View {
        Group {
            if service.calls.isEmpty {
                emptyStateView
            } else {
                content
            }
        }
        .navigationTitle("Statistics")
    }
}

private extension OwlStatsView {
    /// Sorts distribution data by key to ensure consistent display order.
    func distributionData(data: [String: Int]) -> [(key: String, value: Int)] {
        data.sorted(by: { $0.key < $1.key })
    }

    /// Returns the proportional bar width based on the value and total calls.
    func getWidth(value: Int, geo: GeometryProxy) -> CGFloat {
        geo.size.width * CGFloat(value) / CGFloat(max(1, service.calls.count))
    }
}

private extension OwlStatsView {
    /// Main scrollable statistics content including overview, distributions, and slowest endpoint information.
    @ViewBuilder
    var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                let stats = service.stats

                overviewSection(stats)

                distributionSection(
                    title: "Status Code Distribution",
                    data: stats.statusCodeDistribution
                )

                distributionSection(
                    title: "Requests by Method",
                    data: stats.methodDistribution
                )

                slowestSection(stats)
            }
            .padding()
        }
    }

    /// Displays the main overview statistics such as total calls, success rate, error rate, and average response time.
    func overviewSection(_ stats: OwlStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Total", "\(stats.totalCalls)")
                statCard("Success", String(format: "%.1f%%", stats.successRate))
                statCard("Error", String(format: "%.1f%%", stats.errorRate))
                statCard("Avg", String(format: "%.0f ms", stats.avgResponseTime))
            }
        }
    }

    /// Card-style view used to present a single statistic value and label.
    func statCard(_ title: String, _ value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    /// Displays a distribution chart for statistical data such as status codes or HTTP methods.
    func distributionSection(title: String, data: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(distributionData(data: data), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .frame(width: 60, alignment: .leading)

                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.blue.opacity(0.5))
                            .frame(
                                width: getWidth(value: value, geo: geo),
                                height: 20
                            )
                    }
                    .frame(height: 20)

                    Text("\(value)")
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }

    /// Displays the list of the five slowest endpoints based on response duration.
    func slowestSection(_ stats: OwlStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top 5 Slowest Endpoints").font(.headline)

            ForEach(stats.slowestEndpoints, id: \.id) { call in
                HStack {
                    Text(call.method)
                        .bold()
                        .frame(width: 60)

                    VStack(alignment: .leading) {
                        Text(call.endpoint)
                            .lineLimit(1)
                        Text(call.server)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(call.duration) ms")
                        .bold()
                }
                .padding(.vertical, 4)
            }
        }
    }

    /// Empty state shown when no network calls have been captured yet.
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.secondary)

            Text("No Statistics Yet")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Waiting for network activity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 150)
        .frame(maxWidth: .infinity)
    }
}
