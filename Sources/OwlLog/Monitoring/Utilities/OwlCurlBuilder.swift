//
//  OwlCurlBuilder
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A utility for building cURL commands.
public enum OwlCurlBuilder {
    /// Headers that are noise for manual replay — either auto-computed by curl or iOS-injected.
    private static let excludedHeaderNames: Set<String> = [
        "content-length",
        "accept-encoding",
        "accept-language",
        "connection",
        "user-agent",
    ]

    /// Generates a cURL command from a URL request.
    public static func generate(from request: URLRequest) -> String {
        var parts: [String] = []

        let url = request.url.map {
            $0.absoluteString.replacingOccurrences(of: "'", with: "%27")
        } ?? ""

        parts.append("curl -X \(request.httpMethod ?? "GET") '\(url)'")

        request.allHTTPHeaderFields?
            .filter { key, _ in
                !excludedHeaderNames.contains(key.lowercased())
            }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .forEach { key, value in
                let escaped = value.replacingOccurrences(of: "'", with: "\\'")
                parts.append("-H '\(key): \(escaped)'")
            }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8),
           !bodyString.isEmpty {
            let escaped = bodyString.replacingOccurrences(of: "'", with: "\\'")
            parts.append("-d '\(escaped)'")
        }

        return parts.joined(separator: " \\\n  ")
    }
}
