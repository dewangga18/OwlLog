//
//  OwlHeaderParser
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A utility for parsing headers.
public enum OwlHeaderParser {
    /// Returns the content type from a dictionary of headers.
    public static func contentType(from headers: [String: String]?) -> String {
        guard let headers else { return "Unknown content type" }

        return headers.first {
            $0.key.lowercased() == "content-type"
        }?.value ?? "Unknown content type"
    }
}
