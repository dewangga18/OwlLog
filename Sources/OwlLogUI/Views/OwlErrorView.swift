//
//  OwlErrorView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlErrorView: View {
    public let call: OwlHTTPCall

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        if let errorModel = call.error {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(errorModel.displayTitle)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }

                    Divider()

                    if let code = errorModel.resolvedCode {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Code")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(code)")
                                .font(.system(.body, design: .monospaced))
                        }

                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(errorModel.description)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    if let stack = errorModel.stackTrace,
                       !stack.isEmpty
                    {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        } else {
            EmptyView()
        }
    }
}
