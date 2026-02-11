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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = call.request?.curl ?? ""
                    } label: {
                        Label("Copy cURL", systemImage: "doc.on.doc")
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
                            UIPasteboard.general.string = string
                        }
                    }
                }
            } message: {
                replayMessage
            }
    }
}

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

    @ViewBuilder
    var tabView: some View {
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
            .navigationBarTitleDisplayMode(.inline)
            .if(true) { view in
                if #available(iOS 26.0, *) {
                    view.tabBarMinimizeBehavior(.onScrollDown)
                } else {
                    view
                }
            }
        } else {
            TabView {
                OwlHeadersView(
                    call: call,
                    onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                    isReplaying: isReplaying
                )
                .tabItem {
                    Label("Headers", systemImage: "list.bullet.rectangle.portrait")
                }

                if call.response != nil {
                    OwlResponseView(call: call)
                        .tabItem {
                            Label("Response", systemImage: "arrow.uturn.backward.circle")
                        }
                }

                if call.error != nil {
                    OwlErrorView(call: call)
                        .tabItem {
                            Label("Error", systemImage: "exclamationmark.triangle")
                        }
                }
            }
            .navigationTitle("Call Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

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
