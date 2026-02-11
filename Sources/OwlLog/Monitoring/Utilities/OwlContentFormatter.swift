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
    public static func convertToString(_ body: Any) -> String {
        if let data = body as? Data {
            return String(decoding: data, as: UTF8.self)
        }
        return String(describing: body)
    }

    public static func detectContentType(
        headers: [String: String]?,
        body: Any?
    ) -> OwlContentType {
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
            return String(decoding: formatted, as: UTF8.self)
        } catch {
            return String(describing: json)
        }
    }

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

    public static func formatHTML(_ html: Any) -> String {
        return formatXML(html)
    }
}
