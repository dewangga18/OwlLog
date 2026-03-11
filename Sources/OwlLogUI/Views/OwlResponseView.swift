//
//  OwlResponseView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// View responsible for displaying the HTTP response body with formatting based on its detected content type.
public struct OwlResponseView: View {
    /// HTTP call containing the response data to display.
    private let call: OwlHTTPCall

    /// Formatted string representation of the response body.
    @State private var formattedContent: String = ""

    /// Flag to ensure the formatting task runs only once.
    @State private var freshTask = true

    public init(call: OwlHTTPCall) {
        self.call = call
    }

    /// Root container view that prepares the response content  when the view appears.
    public var body: some View {
        contentView
            .onAppear(perform: prepareContent)
    }
}

private extension OwlResponseView {
    /// Prepares and formats the response body based on the detected content type.
    func prepareContent() {
        guard freshTask else { return }
        freshTask = false

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

    /// Copies the raw response body content to the clipboard.
    func handleCopy() {
        OwlClipboard.copy(OwlContentFormatter.convertToString(body))
    }
}

private extension OwlResponseView {
    /// Main content builder that determines whether a response body exists and renders the appropriate UI structure.
    @ViewBuilder
    var contentView: some View {
        if let body = call.response?.body, let headers = call.response?.headers {
            let contentType = OwlContentFormatter.detectContentType(headers: headers, body: body)

            VStack(spacing: 0) {
                headerSection(contentType: contentType, body: body)

                ScrollView {
                    buildContent(contentType: contentType)
                }
            }
        } else {
            EmptyView()
        }
    }

    /// Builds the header section displaying the detected content type, response size, and a copy action.
    func headerSection(contentType: OwlContentType, body: Any) -> some View {
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

            Button(action: handleCopy) {
                Label("Response", systemImage: "doc.on.doc")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.owlSecondaryBackground)
    }

    /// Builds the response content view depending on the detected content type.
    @ViewBuilder
    func buildContent(contentType: OwlContentType) -> some View {
        Group {
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
        .padding(16)
    }

    /// Displays formatted JSON content in a horizontally scrollable view using a monospaced font for readability.
    func buildJsonContent() -> some View {
        ScrollView(.horizontal) {
            Text(formattedContent)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    /// Displays formatted XML or HTML content using a monospaced font.
    func buildXmlContent() -> some View {
        Text(formattedContent)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
    }

    /// Placeholder view shown when the response content is an image and preview rendering is not yet supported.
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

    /// Displays plain text response content using a monospaced font.
    func buildTextContent() -> some View {
        Text(formattedContent)
            .font(.system(size: 12, design: .monospaced))
            .textSelection(.enabled)
    }
}
