//
//  OwlStatsView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlStatsView: View {
    @ObservedObject var service: OwlService

    public init(service: OwlService) {
        self.service = service
    }

    public var body: some View {
        content
            .navigationTitle("Statistics")
    }
}

private extension OwlStatsView {
    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        let calls = service.calls

        if calls.isEmpty {
            emptyStateView
        } else {
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
    }

    // MARK: - Overview Section

    private func overviewSection(_ stats: OwlStats) -> some View {
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

    // MARK: - Stat Card

    private func statCard(_ title: String, _ value: String) -> some View {
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

    // MARK: - Distribution Section

    private func distributionSection(title: String, data: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack {
                    Text(key)
                        .frame(width: 60, alignment: .leading)

                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.blue.opacity(0.5))
                            .frame(
                                width: geo.size.width * CGFloat(value) / CGFloat(max(1, service.calls.count)),
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

    // MARK: - Slowest Section

    private func slowestSection(_ stats: OwlStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top 5 Slowest Endpoints")
                .font(.headline)

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

    // MARK: - Empty State View

    private var emptyStateView: some View {
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
