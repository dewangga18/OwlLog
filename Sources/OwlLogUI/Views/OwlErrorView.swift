//
//  OwlErrorView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// The error view for OwlLog.
public struct OwlErrorView: View {
    /// The HTTP call to display.
    public let call: OwlHTTPCall

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        content
    }
}

private extension OwlErrorView {
    /// The main content view for the error view.
    @ViewBuilder
    var content: some View {
        if let errorHttp = call.error {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    errorSection(errorHttp: errorHttp)

                    codeSection(errorHttp: errorHttp)

                    descriptionSection(errorHttp: errorHttp)

                    stackTraceSection(errorHttp: errorHttp)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        } else {
            EmptyView()
        }
    }

    /// The stack trace section for the error view.
    @ViewBuilder
    func stackTraceSection(errorHttp: OwlHTTPError) -> some View {
        if let stack = errorHttp.stackTrace, !stack.isEmpty {
            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Stacktrace")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(stack)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    /// The description section for the error view.
    @ViewBuilder
    func descriptionSection(errorHttp: OwlHTTPError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(errorHttp.description)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    /// The error section for the error view.
    @ViewBuilder
    func errorSection(errorHttp: OwlHTTPError) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Error")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(errorHttp.displayTitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }

        Divider()
    }

    /// The code section for the error view.
    @ViewBuilder
    func codeSection(errorHttp: OwlHTTPError) -> some View {
        if let code = errorHttp.resolvedCode {
            VStack(alignment: .leading, spacing: 4) {
                Text("Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(code)")
                    .font(.system(.body, design: .monospaced))
            }

            Divider()
        }
    }
}
