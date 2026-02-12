//
//  OwlSummaryHeaderView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlSummaryHeaderView: View {
    let call: OwlHTTPCall
    let onReplay: (() -> Void)?
    let isReplaying: Bool

    public init(
        call: OwlHTTPCall,
        onReplay: (() -> Void)? = nil,
        isReplaying: Bool = false
    ) {
        self.call = call
        self.onReplay = onReplay
        self.isReplaying = isReplaying
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(" [\(call.method) • \(statusText(statusCode))]")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor(statusCode))

                Text(call.endpoint)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }

            Spacer()

            quickActions
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Computed Properties & Functions

private extension OwlSummaryHeaderView {
    var statusCode: Int {
        call.response?.status ?? -1
    }

    func statusText(_ code: Int) -> String {
        code == -1 ? "ERROR" : "\(code)"
    }

    func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500...: return .red
        default: return .red
        }
    }
}

// MARK: - Computed Views

private extension OwlSummaryHeaderView {
    var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                OwlClipboard.copy(call.uri)
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
