//
//  OwlRowView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import SwiftUI

public struct OwlRowView: View {
    public let title: String
    public let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title):")
                .fontWeight(.semibold)
                .textSelection(.enabled)

            Text(value)
                .textSelection(.enabled)
        }
    }
}
