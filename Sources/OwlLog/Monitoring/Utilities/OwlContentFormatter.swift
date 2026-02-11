//
//  OwlContentFormatter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public enum OwlContentType: String {
    case json
    case xml
    case html
    case image
    case text
}

public enum OwlContentFormatter {
    public static func detectContentType(
        headers: [String: String]?,
        body: Any?
    ) -> OwlContentType {
        if let headers {
            let contentType = headers["content-type"] ?? headers["Content-Type"]
            if let type = contentType?.lowercased() {
                if type.contains("json") { return .json }
                if type.contains("xml") { return .xml }
                if type.contains("html") { return .html }
                if type.contains("image") { return .image }
                if type.contains("text") { return .text }
            }
        }

        if let string = body as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
                if let data = trimmed.data(using: .utf8),
                   (try? JSONSerialization.jsonObject(with: data)) != nil
                {
                    return .json
                }
            }

            if trimmed.hasPrefix("<?xml") || trimmed.hasPrefix("<") {
                return .xml
            }
        }

        if body is [Any] || body is [String: Any] {
            return .json
        }

        return .text
    }

    public static func formatJSON(_ json: Any) -> String {
        do {
            if let string = json as? String,
               let data = string.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data)
            {
                let formatted = try JSONSerialization.data(
                    withJSONObject: object,
                    options: [.prettyPrinted]
                )
                return String(decoding: formatted, as: UTF8.self)
            }

            let formatted = try JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted]
            )

            return String(decoding: formatted, as: UTF8.self)
        } catch {
            return String(describing: json)
        }
    }

    public static func formatXML(_ xml: String) -> String {
        var result = ""
        var indent = 0
        var index = xml.startIndex

        while index < xml.endIndex {
            if xml[index] == "<" {
                guard let tagEnd = xml[index...].firstIndex(of: ">") else { break }
                let tag = String(xml[index ... tagEnd])

                let isClosing = tag.hasPrefix("</")
                let isSelfClosing = tag.hasSuffix("/>") || tag.hasPrefix("<?")

                if isClosing {
                    indent = max(indent - 1, 0)
                }

                if !result.isEmpty && !result.hasSuffix("\n") {
                    result.append("\n")
                }

                result.append(String(repeating: "  ", count: indent))
                result.append(tag)

                if !isClosing && !isSelfClosing && !tag.hasPrefix("<!") {
                    indent += 1
                }

                index = xml.index(after: tagEnd)
            } else {
                let nextTag = xml[index...].firstIndex(of: "<") ?? xml.endIndex
                let content = xml[index ..< nextTag]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !content.isEmpty {
                    result.append(content)
                }

                index = nextTag
            }
        }

        return result
    }
}
