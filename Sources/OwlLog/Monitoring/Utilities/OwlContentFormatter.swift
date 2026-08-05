//
//  OwlContentFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// The type of content.
public enum OwlContentType: String {
    case json
    case xml
    case html
    case image
    case multipart
    case text
}

/// A utility for formatting content.
public enum OwlContentFormatter {
    /// Converts a body to a string.
    public static func convertToString(_ body: Any) -> String {
        if let data = body as? Data {
            return String(decoding: data, as: UTF8.self)
        }
        return String(describing: body)
    }

    /// Replaces escaped forward slashes (`\/`) with normal slashes (`/`).
    static func unescapeSlashes(_ string: String) -> String {
        string.replacingOccurrences(of: "\\/", with: "/")
    }
    
    /// Extracts key-value parameters from structured request body data.
    /// Pass `headers` so content type detection uses Content-Type header instead of body sniffing.
    public static func extractParameters(from body: Data, headers: [String: String]? = nil) -> [(key: String, value: String)] {
        let contentType = detectContentType(headers: headers, body: body)

        switch contentType {
        case .json:
            return extractJSONParameters(from: body) ?? []
        case .text:
            return extractFormURLEncodedParameters(from: body) ?? []
        default:
            break
        }

        // Fallback: try both
        if let jsonParams = extractJSONParameters(from: body), !jsonParams.isEmpty {
            return jsonParams
        }
        if let formParams = extractFormURLEncodedParameters(from: body), !formParams.isEmpty {
            return formParams
        }
        return []
    }

    /// Parses a JSON object body into displayable top-level key-value pairs.
    private static func extractJSONParameters(from body: Data) -> [(key: String, value: String)]? {
        guard let object = try? JSONSerialization.jsonObject(with: body),
              let dictionary = object as? [String: Any]
        else {
            return nil
        }

        return dictionary
            .map { key, value in (key: key, value: parameterValue(from: value)) }
            .sorted { $0.key < $1.key }
    }

    /// Parses an `application/x-www-form-urlencoded` body into displayable key-value pairs.
    private static func extractFormURLEncodedParameters(from body: Data) -> [(key: String, value: String)]? {
        guard let bodyString = String(data: body, encoding: .utf8),
              !bodyString.isEmpty,
              bodyString.contains("=")
        else {
            return nil
        }

        var components = URLComponents()
        components.percentEncodedQuery = bodyString

        return components.queryItems?
            .map { item in (key: item.name, value: item.value ?? "") }
            .sorted { $0.key < $1.key }
    }

    /// Converts a parameter value into a concise display string.
    private static func parameterValue(from value: Any) -> String {
        if let string = value as? String { return string }

        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
           let string = String(data: data, encoding: .utf8)
        {
            return unescapeSlashes(string)
        }

        return String(describing: value)
    }

    /// Detects the content type of a body.
    public static func detectContentType(headers: [String: String]?, body: Any?) -> OwlContentType {
        if let headers {
            let contentType = headers["content-type"] ?? headers["Content-Type"]
            if let type = contentType?.lowercased() {
                if type.contains("json") {
                    return .json
                }
                if type.contains("xml") {
                    return .xml
                }
                if type.contains("html") {
                    return .html
                }
                if type.contains("image") {
                    return .image
                }
                if type.contains("multipart") {
                    return .multipart
                }
                if type.contains("text") {
                    return .text
                }
            }
        }

        if let data = body as? Data,
           let string = String(data: data, encoding: .utf8) {
            return detectFromString(string)
        }

        if let string = body as? String {
            return detectFromString(string)
        }

        if body is [Any] || body is [String: Any] {
            return .json
        }

        return .text
    }

    /// Detects the content type from a string.
    private static func detectFromString(_ string: String) -> OwlContentType {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            if let data = trimmed.data(using: .utf8),
               (try? JSONSerialization.jsonObject(with: data)) != nil {
                return .json
            }
        }

        if trimmed.hasPrefix("<") {
            return .xml
        }

        return .text
    }

    /// Formats a JSON object.
    public static func formatJSON(_ json: Any) -> String {
        var jsonObject: Any?

        if let data = json as? Data {
            jsonObject = try? JSONSerialization.jsonObject(with: data)
        } else if let string = json as? String,
                  let data = string.data(using: .utf8) {
            jsonObject = try? JSONSerialization.jsonObject(with: data)
        } else {
            jsonObject = json
        }

        guard let object = jsonObject,
              JSONSerialization.isValidJSONObject(object) else {
            if let data = json as? Data {
                return String(decoding: data, as: UTF8.self)
            }
            return String(describing: json)
        }

        do {
            let formatted = try JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted]
            )
            return unescapeSlashes(String(decoding: formatted, as: UTF8.self))
        } catch {
            return String(describing: json)
        }
    }

    /// Formats an XML object.
    public static func formatXML(_ xml: Any) -> String {
        let xmlString = convertToString(xml)
        var result = ""
        var indent = 0
        var index = xmlString.startIndex

        while index < xmlString.endIndex {
            if xmlString[index] == "<" {
                guard let tagEnd = xmlString[index...].firstIndex(of: ">") else {
                    break
                }
                let tag = String(xmlString[index ... tagEnd])

                let isClosing = tag.hasPrefix("</")
                let isSelfClosing = tag.hasSuffix("/>") || tag.hasPrefix("<?")

                if isClosing {
                    indent = max(0, indent - 1)
                }

                result += String(repeating: "  ", count: indent)
                result += tag + "\n"

                if !isClosing && !isSelfClosing {
                    indent += 1
                }

                index = xmlString.index(after: tagEnd)
            } else {
                let nextTag = xmlString[index...].firstIndex(of: "<") ?? xmlString.endIndex
                let content = String(xmlString[index ..< nextTag])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty {
                    result += String(repeating: "  ", count: indent)
                    result += content + "\n"
                }

                index = nextTag
            }
        }

        return result
    }

    /// Formats an HTML object.
    public static func formatHTML(_ html: Any) -> String {
        return formatXML(html)
    }

    /// Formats a [String: String] dictionary as pretty-printed JSON string.
    public static func formatDictAsJSON(_ dict: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return dict.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n")
        }
        return unescapeSlashes(String(decoding: data, as: UTF8.self))
    }

    /// Formats raw body Data as pretty-printed JSON, falls back to plain string.
    /// Returns an empty string for non-UTF-8 binary data (e.g. image bytes) to prevent
    /// callers from receiving and rendering a huge replacement-character String.
    public static func formatBodyAsJSON(_ body: Data) -> String {
        // Try JSON first
        if let jsonObject = try? JSONSerialization.jsonObject(with: body),
           JSONSerialization.isValidJSONObject(jsonObject),
           let formatted = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let string = String(data: formatted, encoding: .utf8)
        {
            return unescapeSlashes(string)
        }

        // Fallback to plain UTF-8 text — use String(data:encoding:) which returns nil
        // for non-UTF-8 bytes, unlike String(decoding:as:) which silently replaces them.
        return String(data: body, encoding: .utf8) ?? ""
    }
}
