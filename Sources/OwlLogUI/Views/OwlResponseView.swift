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
    @State private var formattedContent: String = ""

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    public var body: some View {
        Group {
            if let body = call.response?.body {
                contentView(body: body)
            } else {
                EmptyView()
            }
        }
        .task {
            prepareContent()
        }
    }
}

// MARK: - Funcions

private extension OwlResponseView {
    func prepareContent() {
        guard let body = call.response?.body else { return }

        let headers = call.response?.headers ?? [:]
        let contentType = OwlContentFormatter.detectContentType(headers: headers, body: body)

        switch contentType {
            case .json:
                formattedContent = OwlContentFormatter.formatJSON(body)
            case .xml, .html:
                formattedContent = OwlContentFormatter.formatXML(body)
            default:
                formattedContent = OwlContentFormatter.convertToString(body)
        }
    }
}

// MARK: - Views

private extension OwlResponseView {
    // MARK: - Main Content

    func contentView(body: Any) -> some View {
        let headers = call.response?.headers ?? [:]
        let contentType = OwlContentFormatter.detectContentType(headers: headers, body: body)

        return VStack(spacing: 0) {
            toolbar(contentType: contentType, body: body)

            ScrollView {
                buildContent(contentType: contentType)
                    .padding(16)
            }
        }
    }

    // MARK: - Toolbar Content

    func toolbar(contentType: OwlContentType, body: Any) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                Text(contentType.rawValue.uppercased())
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(4)

            Text("\(call.response?.body?.count ?? 0) bytes")
                .font(.caption2.weight(.bold))

            Spacer()

            Button {
                OwlClipboard.copy(OwlContentFormatter.convertToString(body))
            } label: {
                Label("Response", systemImage: "doc.on.doc")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.owlSecondaryBackground)
    }

    // MARK: - Build Content

    @ViewBuilder
    func buildContent(contentType: OwlContentType) -> some View {
        switch contentType {
            case .json:
                buildJsonContent()

            case .xml, .html:
                buildXmlContent()

            case .image:
                buildImageContent()

            default:
                buildTextContent()
        }
    }

    func buildJsonContent() -> some View {
        ScrollView(.horizontal) {
            Text(formattedContent)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    func buildXmlContent() -> some View {
        Text(formattedContent)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
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

    func buildTextContent() -> some View {
        Text(formattedContent)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
    }
}
