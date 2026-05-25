//
//  OwlRequestView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// The request detail view for OwlLog.
public struct OwlRequestView: View {
    /// The HTTP call containing request and response data to display.
    let call: OwlHTTPCall
    /// Optional callback triggered when the replay action is invoked.
    let onReplay: (() -> Void)?
    /// Indicates whether the replay process is currently active.
    let isReplaying: Bool

    /// Controls the expanded state of the "General" disclosure section.
    @State var isOpenGeneral = true

    /// Controls the expanded state of the "Request" disclosure section.
    @State var isOpenRequest = true

    /// Controls the expanded state of the "Response" disclosure section.
    @State var isOpenResponse = true

    /// Controls the expanded state of the "Form Data Fields" disclosure section.
    @State var isOpenDataField = true

    /// Controls the expanded state of the "Form Data Files" disclosure section.
    @State var isOpenDataFile = true

    /// Controls the expanded state of the "Query Parameters" disclosure section.
    @State var isOpenQueryParams = true

    /// Controls the expanded state of the "Body" disclosure section.
    @State var isOpenBody = true

    /// Controls visibility of the copy URL toast.
    @State private var showCopiedToast = false

    /// Controls visibility of the copy query params toast.
    @State private var showCopiedQueryToast = false

    /// Controls visibility of the copy body toast.
    @State private var showCopiedBodyToast = false

    public init(
        call: OwlHTTPCall,
        onReplay: (() -> Void)? = nil,
        isReplaying: Bool = false
    ) {
        self.call = call
        self.onReplay = onReplay
        self.isReplaying = isReplaying
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                OwlSummaryHeaderView(
                    call: call,
                    onReplay: onReplay,
                    isReplaying: isReplaying,
                    showCopiedToast: $showCopiedToast
                )

                generalSection
                queryParamsSection
                bodySection
                requestHeadersSection
                responseHeadersSection
                formDataFieldsSection
                formDataFilesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .toast("🦉 URL copied!", isShowing: $showCopiedToast)
        .toast("🦉 Query params copied!", isShowing: $showCopiedQueryToast)
        .toast("🦉 Body copied!", isShowing: $showCopiedBodyToast)
    }
}

private extension OwlRequestView {
    /// Displays general information about the HTTP request and response.
    var generalSection: some View {
        DisclosureGroup("General", isExpanded: $isOpenGeneral) {
            VStack(alignment: .leading, spacing: 8) {
                OwlRowView(title: "Request URL", value: call.uri)
                OwlRowView(title: "Request Method", value: call.method)
                OwlRowView(
                    title: "Status Code",
                    value: "\(call.response?.status ?? -1)"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
    }

    /// Displays query parameters as a separate section with formatted JSON and a copy button.
    @ViewBuilder var queryParamsSection: some View {
        if let queryParams = call.request?.queryParameters, !queryParams.isEmpty {
            let formatted = OwlContentFormatter.formatDictAsJSON(queryParams)
            DisclosureGroup("Query Parameters", isExpanded: $isOpenQueryParams) {
                VStack(spacing: 0) {
                    // Header bar
                    HStack {
                        Text("\(queryParams.count) param\(queryParams.count == 1 ? "" : "s")")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            OwlClipboard.copy(formatted)
                            showCopiedQueryToast = true
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.owlSecondaryBackground)

                    // Content
                    ScrollView(.horizontal) {
                        Text(formatted)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .cornerRadius(8)
                .padding(.top, 8)
            }
        }
    }

    /// Displays request body as a separate section with formatted JSON and a copy button.
    @ViewBuilder var bodySection: some View {
        if let body = call.request?.body, !body.isEmpty {
            let formatted = OwlContentFormatter.formatBodyAsJSON(body)
            if !formatted.isEmpty {
                DisclosureGroup("Body", isExpanded: $isOpenBody) {
                    VStack(spacing: 0) {
                        // Header bar
                        HStack {
                            Text("\(body.count) bytes")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                OwlClipboard.copy(formatted)
                                showCopiedBodyToast = true
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.owlSecondaryBackground)

                        // Content
                        ScrollView(.horizontal) {
                            Text(formatted)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .cornerRadius(8)
                    .padding(.top, 8)
                }
            }
        }
    }

    /// Displays the request headers associated with the HTTP call.
    @ViewBuilder var requestHeadersSection: some View {
        if let headers = call.request?.sortedHeaders {
            DisclosureGroup("Request Headers", isExpanded: $isOpenRequest) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(headers, id: \.key) { key, value in
                        OwlRowView(title: key, value: value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }

    /// Displays response headers.
    @ViewBuilder var responseHeadersSection: some View {
        if let responseHeaders = call.response?.sortedHeaders {
            DisclosureGroup("Response Headers", isExpanded: $isOpenResponse) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(responseHeaders, id: \.key) { key, value in
                        OwlRowView(title: key, value: value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }

    /// Displays the response headers returned by the server.
    @ViewBuilder var formDataFieldsSection: some View {
        if let fields = call.request?.formDataFields, !fields.isEmpty {
            DisclosureGroup("Form Data Fields", isExpanded: $isOpenDataField) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(fields, id: \.name) { field in
                        OwlRowView(title: field.name, value: field.value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }

    /// Displays uploaded files included in the HTTP request form data.
    @ViewBuilder var formDataFilesSection: some View {
        if let files = call.request?.formDataFiles, !files.isEmpty {
            DisclosureGroup("Form Data Files", isExpanded: $isOpenDataFile) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(files, id: \.fileName) { file in
                        OwlRowView(title: file.fileName, value: file.contentType)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }
}
