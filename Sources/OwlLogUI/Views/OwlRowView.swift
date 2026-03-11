//
//  OwlRowView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import SwiftUI

/// A reusable row view used to display a key–value pair such as HTTP headers, metadata, or request information.
public struct OwlRowView: View {
    /// Title or key displayed in the row.
    public let title: String

    /// Value associated with the title.
    public let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    /// Layout displaying the title and value in a vertical stack with selectable text for easier copying.
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
