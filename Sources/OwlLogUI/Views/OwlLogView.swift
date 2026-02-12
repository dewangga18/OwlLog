//
//  OwlLogView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlLogView: View {
    @ObservedObject private var service: OwlService

    @State private var query: String = ""
    @State private var isSearching = false
    @State private var showStats = false

    public init(service: OwlService) {
        self.service = service
    }

    public var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack {
                bodyView
            }
            .sheet(isPresented: $showStats) {
                NavigationStack {
                    OwlStatsView(service: service)
                        .toolbar {
                            ToolbarItem(placement: .owlTrailing) {
                                Button("Done") { showStats = false }
                            }
                        }
                }
            }
        } else {
            NavigationView {
                bodyView
            }
            .sheet(isPresented: $showStats) {
                NavigationView {
                    OwlStatsView(service: service)
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button("Done") { showStats = false }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Computed Variables

private extension OwlLogView {
    var filteredCalls: [OwlHTTPCall] {
        service.filteredCalls(query)
    }

    func statusCode(call: OwlHTTPCall) -> Int {
        call.response?.status ?? -1
    }

    func statusColor(_ code: Int) -> Color {
        switch code {
            case 200..<300: return .green
            case 300..<400: return .orange
            case 400...: return .red
            default: return .red
        }
    }
}

// MARK: - View Builders

private extension OwlLogView {
    // MARK: - Body view

    var bodyView: some View {
        List {
            if filteredCalls.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredCalls, id: \.id) { call in
                    callRow(call)
                }
            }
        }
        .navigationTitle(isSearching ? "" : "Owl Log")
        .searchable(text: $query, placement: .owlAutomatic)
        .toolbar {
            ToolbarItem(placement: .owlLeading) {
                Button("Done") {
                    service.closeInspector()
                }
            }

            ToolbarItemGroup(placement: .owlTrailing) {
                Button {
                    isSearching.toggle()
                } label: {
                    Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                }

                Menu {
                    Button {
                        showStats = true
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                    }

                    Button(role: .destructive) {
                        service.clearCalls()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Call Row

    func callRow(_ call: OwlHTTPCall) -> some View {
        NavigationLink {
            if call.response?.status != nil {
                OwlDetailView(call: call)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(call.method) \(call.endpoint)")
                        .foregroundColor(call.error != nil ? .red : .primary)

                    Spacer()

                    statusView(for: call)
                }

                Text(call.server)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(call.createdTime.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(call.duration) ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(call.response?.status == nil)
    }

    // MARK: - Status View

    @ViewBuilder
    func statusView(for call: OwlHTTPCall) -> some View {
        if let status = call.response?.status {
            Text("\(status)")
                .fontWeight(.semibold)
                .foregroundColor(statusColor(statusCode(call: call)))
        } else {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.green)
        }
    }

    // MARK: - Empty State View

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: query.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(.secondary)

            Text(query.isEmpty
                ? "No Logged Data"
                : "No calls match \"\(query)\"")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(query.isEmpty
                ? "No network activity detected."
                : "No matches found.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 200)
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}
