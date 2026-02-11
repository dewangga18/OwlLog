//
//  OwlCurlBuilder
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public enum OwlCurlBuilder {
    public static func generate(from request: URLRequest) -> String {
        var components: [String] = []

        components.append("curl -X \(request.httpMethod ?? "GET")")

        request.allHTTPHeaderFields?.forEach { key, value in
            components.append("-H \"\(key): \(value)\"")
        }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8)
        {
            let escaped = bodyString.replacingOccurrences(of: "'", with: "\\'")
            components.append("-d '\(escaped)'")
        }

        if let url = request.url {
            components.append("\"\(url.absoluteString)\"")
        }

        return components.joined(separator: " ")
    }
}
