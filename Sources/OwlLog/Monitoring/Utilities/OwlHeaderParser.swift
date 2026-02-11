//
//  OwlHeaderParser
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public enum OwlHeaderParser {
    public static func contentType(from headers: [String: String]?) -> String {
        guard let headers else { return "Unknown content type" }

        return headers.first {
            $0.key.lowercased() == "content-type"
        }?.value ?? "Unknown content type"
    }
}
