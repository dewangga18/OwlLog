//
//  OwlResponseView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlResponseView: View {
    private let call: OwlHTTPCall
    @State private var showFormatted: Bool = true

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        Group {
            if let body = call.response?.body {
                contentView(body: body)
            } else {
                emptyView
            }
        }
    }
}

// MARK:  Main Content

private extension OwlResponseView {
    func contentView(body: Any) -> some View {
        let headers = call.response?.headers ?? [:]
        let contentType = OwlContentFormatter.detectContentType(headers: headers, body: body)

        return VStack(spacing: 0) {
            toolbar(contentType: contentType, body: body)

            ScrollView {
                buildContent(contentType: contentType, body: body)
                    .padding(16)
            }
        }
    }

    var emptyView: some View {
        VStack {
            Spacer()
            Text("There is no response")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK:  Toolbar Content

private extension OwlResponseView {
    func toolbar(contentType: OwlContentType, body: Any) -> some View {
        HStack {
            if contentType == .json || contentType == .xml {
                Picker("", selection: $showFormatted) {
                    Label("Formatted", systemImage: "chevron.left.slash.chevron.right")
                        .tag(true)
                    Label("Raw", systemImage: "text.alignleft")
                        .tag(false)
                }
                .pickerStyle(.segmented)
            }

            Spacer()

            Button {
                UIPasteboard.general.string = OwlContentFormatter.convertToString(body)
            } label: {
                Image(systemName: "doc.on.doc")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// MARK:  Build Content

private extension OwlResponseView {
    @ViewBuilder
    func buildContent(contentType: OwlContentType, body: Any) -> some View {
        switch contentType {
            case .json:
                buildJsonContent(body)

            case .xml, .html:
                buildXmlContent(body)

            case .image:
                buildImageContent()

            default:
                buildTextContent(body)
        }
    }

    func buildJsonContent(_ body: Any) -> some View {
        if showFormatted {
            let formatted = OwlContentFormatter.formatJSON(body)
            return AnyView(
                ScrollView(.horizontal) {
                    Text(formatted)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                }
            )
        } else {
            return AnyView(
                Text(String(describing: body))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            )
        }
    }

    func buildXmlContent(_ body: Any) -> some View {
        if showFormatted {
            let formatted = OwlContentFormatter.formatXML(body)
            return AnyView(
                Text(formatted)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            )
        } else {
            return AnyView(
                Text(OwlContentFormatter.convertToString(body))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            )
        }
    }

    func buildImageContent() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("Image preview not yet supported")
                .foregroundColor(.gray)

            Text("Check the Headers tab for image metadata")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    func buildTextContent(_ body: Any) -> some View {
        Text(OwlContentFormatter.convertToString(body))
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
    }
}
