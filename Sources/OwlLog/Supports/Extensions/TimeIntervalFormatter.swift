//
//  DurationFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public extension TimeInterval {
    var owlFormattedDuration: String {
        let safeInterval = max(0, self)
        let milliseconds = Int(safeInterval * 1000)

        if milliseconds < 1000 {
            return "\(milliseconds) ms"
        } else if milliseconds < 60_000 {
            return String(format: "%.2f s", safeInterval)
        } else {
            let minutes = milliseconds / 60_000
            let seconds = Double(milliseconds % 60_000) / 1000
            return "\(minutes)m \(String(format: "%.1f", seconds))s"
        }
    }
}
