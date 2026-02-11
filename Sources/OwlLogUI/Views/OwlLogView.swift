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
        if #available(iOS 16.0, *) {
            NavigationStack {
                bodyView
            }
            .sheet(isPresented: $showStats) {
                NavigationStack {
                    OwlStatsView(service: service)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
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
                        .navigationBarItems(trailing: Button("Done") { showStats = false })
                }
            }
        }
    }
}

private extension OwlLogView {
    // MARK: Body view

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
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    service.closeInspector()
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
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

    // MARK: Filter Section

    var filteredCalls: [OwlHTTPCall] {
        service.filteredCalls(query)
    }

    // MARK: Call Row Sections

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
        .disabled(call.response?.status == nil)
    }

    // MARK: Status View

    @ViewBuilder
    func statusView(for call: OwlHTTPCall) -> some View {
        if let status = call.response?.status {
            Text("\(status)")
                .fontWeight(.semibold)
                .foregroundColor(call.error != nil ? .red : .green)
        } else {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.green)
        }
    }

    // MARK: Empty State View

    var emptyStateView: some View {
        VStack {
            Spacer()

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
                    ? "API requests will appear here once detected."
                    : "Try adjusting your search or filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}
