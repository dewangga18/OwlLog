//
//  OwlCurlBuilder
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A utility for building cURL commands.
public enum OwlCurlBuilder {

    /// Headers that add no value to a manually replayed curl command.
    private static let excludedHeaderNames: Set<String> = [
        "content-type", "Content-Type",
        "content-length",       // curl computes this automatically
        "accept-encoding",      // curl sets its own
        "accept-language",      // iOS locale noise
        "connection",           // transport-level, irrelevant
        "user-agent",           // optional: remove iOS UA noise; delete this line to keep it
    ]

    /// Generates a cURL command from a URL request.
    public static func generate(from request: URLRequest) -> String {
        var parts: [String] = []

        // Method + URL (query params are already in the URL)
        let url = request.url.map {
            $0.absoluteString.replacingOccurrences(of: "\"", with: "%22")
        } ?? ""

        parts.append("curl -X \(request.httpMethod ?? "GET") \"\(url)\"")

        request.allHTTPHeaderFields?
            .filter { key, _ in
                !excludedHeaderNames.contains(key.lowercased()) &&
                !OwlHeaderParser.isExcludedRequestHeader(key)
            }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .forEach { key, value in
                let escaped = value.replacingOccurrences(of: "'", with: "\\'")
                parts.append("-H '\(key): \(escaped)'")
            }

        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8),
           !bodyString.isEmpty {
            let escaped = bodyString.replacingOccurrences(of: "'", with: "\\'")
            parts.append("-d '\(escaped)'")
        }

        return parts.joined(separator: " \\\n  ")
    }
}