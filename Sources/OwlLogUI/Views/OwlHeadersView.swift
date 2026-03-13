//
//  OwlHeadersView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

/// The header view for OwlLog.
public struct OwlHeadersView: View {
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

    /// Controls the expanded state of the "Data Field" disclosure section.
    @State var isOpenDataField = true

    /// Controls the expanded state of the "Data File" disclosure section.
    @State var isOpenDataFile = true

    /// Controls visibility of the copy URL toast.
    @State private var showCopiedToast = false

    public init(
        call: OwlHTTPCall,
        onReplay: (() -> Void)? = nil,
        isReplaying: Bool = false
    ) {
        self.call = call
        self.onReplay = onReplay
        self.isReplaying = isReplaying
    }

    /// The main body rendering the header sections of the HTTP call.
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
                requestHeadersSection
                responseHeadersSection
                formDataFieldsSection
                formDataFilesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .toast("🦉 URL copied!", isShowing: $showCopiedToast)
    }
}

private extension OwlHeadersView {
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

    /// Displays the request headers associated with the HTTP call.
    @ViewBuilder
    var requestHeadersSection: some View {
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

    /// Displays the response headers returned by the server.
    @ViewBuilder
    var responseHeadersSection: some View {
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

    /// Displays form data fields included in the HTTP request body.
    @ViewBuilder
    var formDataFieldsSection: some View {
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
    @ViewBuilder
    var formDataFilesSection: some View {
        if let files = call.request?.formDataFiles, !files.isEmpty {
            DisclosureGroup("Form Data Files", isExpanded: $isOpenDataFile) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(files, id: \.fileName) { file in
                        OwlRowView(
                            title: file.fileName,
                            value: file.contentType
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
        }
    }
}
