//
//  OwlDetailView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlDetailView: View {
    let call: OwlHTTPCall

    @State private var isReplaying = false
    @State private var showResultDialog = false
    @State private var replayResponse: HTTPURLResponse?
    @State private var replayData: Data?
    @State private var replayError: Error?

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        tabView
            .toolbar {
                ToolbarItem(placement: .owlTrailing) {
                    Button {
                        OwlClipboard.copy(call.request?.curl ?? "")
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("cURL")
                        }
                    }
                }
            }
            .alert("Replay Result", isPresented: $showResultDialog) {
                Button("Close", role: .cancel) {}

                if replayData != nil {
                    Button("Copy Response") {
                        if let data = replayData,
                           let string = String(data: data, encoding: .utf8)
                        {
                            OwlClipboard.copy(string)
                        }
                    }
                }
            } message: {
                replayMessage
            }
    }
}

// MARK: - Functions

private extension OwlDetailView {
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
    // MARK: - Tab View

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

    // MARK: - Fallback Tab View

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

    // MARK: - Replay Message

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
