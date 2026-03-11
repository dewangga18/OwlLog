//
//  OwlDetailView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// The detail view for OwlLog.
public struct OwlDetailView: View {
    /// The HTTP call to display.
    let call: OwlHTTPCall

    /// The state for the replay functionality.
    @State private var isReplaying = false
    /// The state for the result dialog.
    @State private var showResultDialog = false
    /// The response for the replay functionality.
    @State private var replayResponse: HTTPURLResponse?
    /// The data for the replay functionality.
    @State private var replayData: Data?
    /// The error for the replay functionality.
    @State private var replayError: Error?

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        tabView
            .toolbar(content: toolbarItems)
            .alert("Replay Result", isPresented: $showResultDialog) {
                Button("Close", role: .cancel) {}

                replayAlertButtons
            } message: {
                replayMessage
            }
    }
}

// MARK: - Functions

private extension OwlDetailView {
    /// Handles the copy curl functionality.
    func handleCopyCurl() {
        OwlClipboard.copy(call.request?.curl ?? "")
    }

    /// Handles the replay functionality.
    func handleReplay() {
        guard OwlService.shared.urlSession != nil else {
            return
        }

        isReplaying = true

        Task {
            do {
                let (response, data) = try await OwlService.shared.replay(call)

                await MainActor.run {
                    self.isReplaying = false
                    self.replayResponse = response
                    self.replayData = data
                    self.replayError = nil
                    self.showResultDialog = true
                }

            } catch {
                await MainActor.run {
                    self.isReplaying = false
                    self.replayError = error
                    self.replayResponse = nil
                    self.replayData = nil
                    self.showResultDialog = true
                }
            }
        }
    }
}

// MARK: - Views

private extension OwlDetailView {
    /// The buttons for the replay alert.
    @ViewBuilder var replayAlertButtons: some View {
        if replayData != nil {
            Button("Copy Response") {
                if let data = replayData,
                   let string = String(data: data, encoding: .utf8)
                {
                    OwlClipboard.copy(string)
                }
            }
        }
    }

    /// The toolbar items for the detail view.
    func toolbarItems() -> some ToolbarContent {
        ToolbarItem(placement: .owlTrailing) {
            Button(action: handleCopyCurl) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("cURL")
                }
            }
        }
    }

    /// The tab view for the detail view.
    @ViewBuilder
    var tabView: some View {
        #if swift(>=6.0)
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Headers", systemImage: "network") {
                    OwlHeadersView(
                        call: call,
                        onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                        isReplaying: isReplaying
                    )
                }

                if call.response != nil {
                    Tab("Response", systemImage: "doc.text.image") {
                        OwlResponseView(call: call)
                    }
                }

                if call.error != nil {
                    Tab("Error", systemImage: "xmark.octagon") {
                        OwlErrorView(call: call)
                    }
                }
            }
            .navigationTitle("Call Details")
            .owlNavigationBarTitleDisplayModeInline()
            .if(true) { view in
                if #available(iOS 26.0, *) {
                    view.tabBarMinimizeBehavior(.onScrollDown)
                } else {
                    view
                }
            }
        } else {
            fallbackTabView
        }
        #else
        fallbackTabView
        #endif
    }

    /// The fallback tab view for the detail view.
    @ViewBuilder
    var fallbackTabView: some View {
        TabView {
            OwlHeadersView(
                call: call,
                onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                isReplaying: isReplaying
            )
            .tabItem {
                Label("Headers", systemImage: "network")
            }

            if call.response != nil {
                OwlResponseView(call: call)
                    .tabItem {
                        Label("Response", systemImage: "doc.text.image")
                    }
            }

            if call.error != nil {
                OwlErrorView(call: call)
                    .tabItem {
                        Label("Error", systemImage: "xmark.octagon")
                    }
            }
        }
        .navigationTitle("Call Details")
        .owlNavigationBarTitleDisplayModeInline()
    }

    /// The replay message for the detail view.
    @ViewBuilder
    var replayMessage: some View {
        if let response = replayResponse {
            VStack(alignment: .leading, spacing: 8) {
                Text("Status: \(response.statusCode)")
                if let data = replayData,
                   let string = String(data: data, encoding: .utf8)
                {
                    Text("Response:")
                        .font(.headline)
                    ScrollView {
                        Text(string)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .frame(maxHeight: 200)
                }
            }
        } else if let error = replayError {
            Text("Error: \(error.localizedDescription)")
        } else {
            Text("Unknown result")
        }
    }
}
