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

    public init(service: OwlService) {
        self.service = service
    }

    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                bodyView
            }
        } else {
            NavigationView {
                bodyView
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
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isSearching.toggle()
                } label: {
                    Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                }

                Menu {
                    Button {
                        // Navigate to stats
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
        service.calls
            .reversed()
            .filter { matches($0) }
    }

    // MARK: Matched Section

    func matches(_ call: OwlHTTPCall) -> Bool {
        guard !query.isEmpty else { return true }

        let normalized = query.lowercased()

        let fields: [String?] = [
            call.method,
            call.endpoint,
            call.server,
            call.uri,
            call.response?.status.map { String($0) },
            call.error?.error.localizedDescription,
            call.error?.stackTrace
        ]

        return fields.contains {
            $0?.lowercased().contains(normalized) ?? false
        }
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

            Text(query.isEmpty
                ? "There is no logged data"
                : "No calls match \"\(query)\"")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
    }
}
