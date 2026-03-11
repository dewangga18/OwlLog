//
//  OwlLogView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// The main log viewer displaying captured HTTP calls.
public struct OwlLogView: View {
    /// Service responsible for providing logged HTTP calls.
    @ObservedObject private var service: OwlService

    /// Search query used to filter HTTP calls.
    @State private var query: String = ""

    /// Indicates whether the search mode is currently active.
    @State private var isSearching = false

    /// Controls presentation of the statistics screen.
    @State private var showStats = false

    public init(service: OwlService) {
        self.service = service
    }

    /// Root view responsible for presenting the log list and the statistics sheet.
    public var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack(root: listContent)
                .sheet(isPresented: $showStats, content: sheetView)
        } else {
            NavigationView(content: listContent)
                .sheet(isPresented: $showStats, content: sheetView)
        }
    }
}

private extension OwlLogView {
    /// Returns HTTP calls filtered using the current search query.
    var filteredCalls: [OwlHTTPCall] {
        service.filteredCalls(query)
    }

    /// Extracts the HTTP response status code from a given call.
    func statusCode(call: OwlHTTPCall) -> Int {
        call.response?.status ?? -1
    }

    /// Maps an HTTP status code to a corresponding UI color.
    func statusColor(_ code: Int) -> Color {
        switch code {
            case 200..<300: return .green
            case 300..<400: return .orange
            case 400...: return .red
            default: return .red
        }
    }
}

private extension OwlLogView {
    /// Builds the main navigation container depending on platform availability.
    @ViewBuilder
    var bodyView: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack(root: listContent)
        } else {
            NavigationView(content: listContent)
        }
    }

    /// Builds the sheet view used to display request statistics.
    /// The sheet is wrapped in a navigation container to allow a toolbar with a dismiss action.
    @ViewBuilder
    func sheetView() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack {
                OwlStatsView(service: service)
                    .toolbar {
                        ToolbarItem(placement: .owlTrailing) {
                            Button("Done") { showStats = false }
                        }
                    }
            }
        } else {
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

    /// Builds the list containing all logged HTTP calls and displays an empty state when no calls match the current filter.
    @ViewBuilder
    func listContent() -> some View {
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
            toolbarDone
            menuBar
        }
    }

    /// Toolbar menu containing search toggle and additional actions such as statistics and clearing logs.
    var menuBar: some ToolbarContent {
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

    /// Toolbar item that dismisses the inspector and closes the log viewer.
    var toolbarDone: some ToolbarContent {
        ToolbarItem(placement: .owlLeading) {
            Button("Done") {
                service.closeInspector()
            }
        }
    }

    /// Builds a row displaying summary information for a single HTTP call.
    func callRow(_ call: OwlHTTPCall) -> some View {
        NavigationLink {
            OwlDetailView(call: call)
        } label: {
            labelCallRow(call)
        }
        .buttonStyle(.plain)
    }

    /// Layout for the visual content of a single log row.
    /// Displays the method, endpoint, server, timestamp, duration, and status indicator.
    @ViewBuilder
    func labelCallRow(_ call: OwlHTTPCall) -> some View {
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

    /// Displays the status indicator for a call including status code or loading state.
    @ViewBuilder
    func statusView(for call: OwlHTTPCall) -> some View {
        if let status = call.response?.status {
            Text("\(status)")
                .fontWeight(.semibold)
                .foregroundColor(statusColor(statusCode(call: call)))
        } else if let code = call.error?.resolvedCode {
            Text("\(code)")
                .fontWeight(.semibold)
                .foregroundColor(.red)
        } else {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.green)
        }
    }

    /// Displays an empty state message when no HTTP calls are available or matched.
    @ViewBuilder
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
