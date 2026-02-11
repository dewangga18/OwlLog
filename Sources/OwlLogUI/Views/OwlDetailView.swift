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
        TabView {
            OwlHeadersView(
                call: call,
                onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                isReplaying: isReplaying
            )
            .tabItem { Text("Headers") }

            OwlResponseView(call: call)
                .tabItem { Text("Response") }

            OwlErrorView(call: call)
                .tabItem { Text("Error") }
        }
        .navigationTitle("HTTP Call Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = call.request?.curl ?? ""
                } label: {
                    Image(systemName: "doc.on.doc")
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
