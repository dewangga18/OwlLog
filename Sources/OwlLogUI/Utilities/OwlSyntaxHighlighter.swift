//
//  OwlSyntaxHighlighter
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public enum OwlSyntaxHighlighter {
    private static let maxHighlightLength = 50_000

    public static func jsonView(_ json: String) -> some View {
        ScrollView {
            if json.isEmpty {
                emptyView
            } else {
                Text(highlightJSON(json))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
        }
    }

    public static func xmlView(_ xml: String) -> some View {
        ScrollView {
            if xml.isEmpty {
                emptyView
            } else {
                Text(highlightXML(xml))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
        }
    }

    private static var emptyView: some View {
        Text("No content")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static func highlightJSON(_ json: String) -> AttributedString {
        let content = truncateIfNeeded(json)
        var attributed = AttributedString(content)

        highlightPattern(#""[^"]+"\s*:"#, in: &attributed, color: .purple)

        highlightPattern(#":\s*"[^"]*""#, in: &attributed, color: .green)

        highlightPattern(#"-?\d+\.?\d*"#, in: &attributed, color: .blue)

        highlightPattern(#"\b(true|false|null)\b"#, in: &attributed, color: .orange)

        return attributed
    }

    private static func highlightXML(_ xml: String) -> AttributedString {
        let content = truncateIfNeeded(xml)
        var attributed = AttributedString(content)

        highlightPattern(#"<[^>]+>"#, in: &attributed, color: .purple)

        highlightPattern(#"\w+=("[^"]*"|'[^']*')"#, in: &attributed, color: .orange)

        return attributed
    }

    private static func truncateIfNeeded(_ text: String) -> String {
        guard text.count > maxHighlightLength else { return text }
        return String(text.prefix(maxHighlightLength)) + "\n\n... (content truncated for performance)"
    }

    private static func highlightPattern(
        _ pattern: String,
        in attributed: inout AttributedString,
        color: Color
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let string = String(attributed.characters)
        let nsString = string as NSString
        let matches = regex.matches(
            in: string,
            range: NSRange(location: 0, length: nsString.length)
        )

        for match in matches {
            if let swiftRange = Range(match.range, in: string),
               let attributedRange = Range(swiftRange, in: attributed)
            {
                attributed[attributedRange].foregroundColor = color
            }
        }
    }
}
