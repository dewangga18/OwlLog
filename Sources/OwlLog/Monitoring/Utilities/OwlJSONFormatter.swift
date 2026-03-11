//
//  OwlJSONFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A utility for formatting JSON.
public enum OwlJSONFormatter {
    /// Returns a pretty-printed JSON string from data.
    public static func prettyPrinted(from data: Data) -> String {
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            let formatted = try JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted]
            )
            return String(data: formatted, encoding: .utf8) ?? ""
        } catch {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
}
