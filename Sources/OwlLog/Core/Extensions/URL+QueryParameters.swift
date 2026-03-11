//
//  URL+QueryParameters
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

extension URL {
    /// Returns the query parameters of the URL as a dictionary.
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems
        else {
            return [:]
        }

        return items.reduce(into: [:]) { result, item in
            result[item.name] = item.value
        }
    }
}
