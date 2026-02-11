//
//  ByteFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public extension Int {
    var owlFormattedBytes: String {
        switch self {
            case ..<1024:
                return "\(self) B"
            case ..<1_048_576:
                return String(format: "%.1f KB", Double(self) / 1024)
            case ..<1_073_741_824:
                return String(format: "%.1f MB", Double(self) / 1_048_576)
            default:
                return String(format: "%.1f GB", Double(self) / 1_073_741_824)
        }
    }
}
