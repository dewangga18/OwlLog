//
//  RelativeFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public extension Date {
    var owlRelativeFormatted: String {
        let difference = Date().timeIntervalSince(self)

        guard difference >= 0 else {
            return "just now"
        }

        switch difference {
            case ..<60:
                return "\(Int(difference))s ago"
            case ..<3600:
                return "\(Int(difference / 60))m ago"
            case ..<86_400:
                return "\(Int(difference / 3600))h ago"
            case ..<604_800:
                return "\(Int(difference / 86_400))d ago"
            default:
                return Self.owlDateTimeFormatter.string(from: self)
        }
    }

    var owlFormattedTime: String {
        Self.owlTimeFormatter.string(from: self)
    }
}

private extension Date {
    static let owlTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    static let owlDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
