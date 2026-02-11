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
        Group {
            if let error = call.error {
                ScrollView {
                    Text(String(describing: error.error))
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            } else {
                VStack {
                    Spacer()
                    Text("There is no error")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }
}
