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
    /// The selected tab for detail content.
    @State private var selectedTab: DetailTab = .headers
    /// Controls visibility of the copied toast.
    @State private var showCopiedToastResponse = false
    @State private var showCopiedToastCurl = false

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        tabView
            .toolbar(content: toolbarCopyCurl)
            .alert("Replay Result", isPresented: $showResultDialog) {
                Button("Close", role: .cancel) {}

                replayAlertButtons
            } message: {
                replayMessage
            }
            .toast("🦉 cURL Copied!", isShowing: $showCopiedToastCurl)
            .toast("🦉 Response Copied!", isShowing: $showCopiedToastResponse)
    }
}

private extension OwlDetailView {

    /// Tabs available in the detail screen.
    enum DetailTab: Hashable {
        case headers
        case response
        case error
    }

    /// Computes tabs that should be shown based on call data.
    var availableTabs: [DetailTab] {
        var tabs: [DetailTab] = [.headers]
        if call.response != nil {
            tabs.append(.response)
        }
        if call.error != nil {
            tabs.append(.error)
        }
        return tabs
    }

    /// Moves the selected tab by a given offset within the available tab range.
    func moveTab(by offset: Int) {
        let tabs = availableTabs
        guard let index = tabs.firstIndex(of: selectedTab) else {
            selectedTab = tabs.first ?? .headers
            return
        }

        let nextIndex = min(max(index + offset, 0), tabs.count - 1)
        guard nextIndex != index else { return }
        selectedTab = tabs[nextIndex]
    }

    /// Handles horizontal swipe gestures to switch between tabs.
    func handleSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        guard abs(horizontal) > abs(vertical) else { return }

        if horizontal <= -40 {
            moveTab(by: 1)
        } else if horizontal >= 40 {
            moveTab(by: -1)
        }
    }
}

private extension OwlDetailView {
    /// Handles the copy curl functionality.
    func handleCopyCurl() {
        OwlClipboard.copy(call.request?.curl ?? "")
        showCopiedToastCurl = true
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

private extension OwlDetailView {
    /// The buttons for the replay alert.
    @ViewBuilder var replayAlertButtons: some View {
        if replayData != nil {
            Button("Copy Response") {
                if let data = replayData,
                   let string = String(data: data, encoding: .utf8)
                {
                    OwlClipboard.copy(string)
                    showCopiedToastResponse = true
                }
            }
        }
    }

    /// The toolbar items for the detail view.
    func toolbarCopyCurl() -> some ToolbarContent {
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
            TabView(selection: $selectedTab) {
                Tab("Headers", systemImage: "network", value: DetailTab.headers) {
                    OwlHeadersView(
                        call: call,
                        onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                        isReplaying: isReplaying
                    )
                }

                if call.response != nil {
                    Tab("Response", systemImage: "doc.text.image", value: DetailTab.response) {
                        OwlResponseView(call: call)
                    }
                }

                if call.error != nil {
                    Tab("Error", systemImage: "xmark.octagon", value: DetailTab.error) {
                        OwlErrorView(call: call)
                    }
                }
            }
            .navigationTitle("Call Details")
            .owlNavigationBarTitleDisplayModeInline()
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded(handleSwipe)
            )
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
        TabView(selection: $selectedTab) {
            OwlHeadersView(
                call: call,
                onReplay: OwlService.shared.urlSession != nil ? handleReplay : nil,
                isReplaying: isReplaying
            )
            .tag(DetailTab.headers)
            .tabItem {
                Label("Headers", systemImage: "network")
            }

            if call.response != nil {
                OwlResponseView(call: call)
                    .tag(DetailTab.response)
                    .tabItem {
                        Label("Response", systemImage: "doc.text.image")
                    }
            }

            if call.error != nil {
                OwlErrorView(call: call)
                    .tag(DetailTab.error)
                    .tabItem {
                        Label("Error", systemImage: "xmark.octagon")
                    }
            }
        }
        .navigationTitle("Call Details")
        .owlNavigationBarTitleDisplayModeInline()
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded(handleSwipe)
        )
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
