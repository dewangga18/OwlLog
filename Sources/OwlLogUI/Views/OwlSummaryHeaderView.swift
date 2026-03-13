//
//  OwlSummaryHeaderView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// Header view displaying a summary of the HTTP call with quick actions.
public struct OwlSummaryHeaderView: View {
    /// HTTP call used to populate the summary information.
    let call: OwlHTTPCall

    /// Optional action to replay the request.
    let onReplay: (() -> Void)?

    /// Indicates whether the replay action is currently in progress.
    let isReplaying: Bool

    /// Controls visibility of the copy URL toast.
    @Binding var showCopiedToast:  Bool

    public init(
        call: OwlHTTPCall,
        onReplay: (() -> Void)? = nil,
        isReplaying: Bool = false,
        showCopiedToast: Binding<Bool>
    ) {
        self.call = call
        self.onReplay = onReplay
        self.isReplaying = isReplaying
        self._showCopiedToast = showCopiedToast
    }

    /// Layout displaying the call summary and quick actions.
    public var body: some View {
        HStack {
            contentSection

            Spacer()

            quickActions
        }
        .padding(.leading, 4)
        .padding(.trailing, 8)
        .padding(.vertical, 12)
    }
}

private extension OwlSummaryHeaderView {
    /// Extracted status code from the HTTP response.
    var statusCode: Int {
        call.response?.status ?? -1
    }

    /// Returns display text for a given status code.
    func statusText(_ code: Int) -> String {
        code == -1 ? "ERROR" : "\(code)"
    }

    /// Returns the display color associated with a status code.
    func statusColor(_ code: Int) -> Color {
        switch code {
            case 200..<300: return .green
            case 300..<400: return .orange
            case 400...: return .red
            default: return .red
        }
    }
}

private extension OwlSummaryHeaderView {
    /// Displays the HTTP method, status code, and endpoint.
    var contentSection: some View {
        VStack(alignment: .leading) {
            Text("[\(call.method) • \(statusText(statusCode))]")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor(statusCode))

            Text(call.endpoint)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
        }
    }

    /// Provides quick actions such as copying the URL or replaying the request.
    @ViewBuilder
    var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                OwlClipboard.copy(call.uri)
                showCopiedToast = true
            } label: {
                Label("URL", systemImage: "doc.on.doc")
            }

            if let onReplay {
                Button {
                    onReplay()
                } label: {
                    if isReplaying {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Label("Replay", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isReplaying)
            }
        }
    }
}
