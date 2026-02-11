//
//  OwlHeadersView
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import OwlLog
import SwiftUI

public struct OwlHeadersView: View {
    let call: OwlHTTPCall
    let onReplay: (() -> Void)?
    let isReplaying: Bool

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
                    isReplaying: isReplaying
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
    }
}

private extension OwlHeadersView {
    
    // MARK: General Section

    var generalSection: some View {
        DisclosureGroup("General") {
            VStack(alignment: .leading, spacing: 8) {
                OwlRowView(title: "Request URL", value: call.uri)
                OwlRowView(title: "Request Method", value: call.method)
                OwlRowView(
                    title: "Status Code",
                    value: "\(call.response?.status ?? -1)"
                )
            }
            .padding(.top, 8)
        }
    }

    // MARK:  Request Headers Section

    var requestHeadersSection: some View {
        DisclosureGroup("Request Headers") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(call.request?.sortedHeaders ?? [], id: \.key) { key, value in
                    OwlRowView(title: key, value: value)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK:  Response Headers Section

    var responseHeadersSection: some View {
        DisclosureGroup("Response Headers") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(call.response?.sortedHeaders ?? [], id: \.key) { key, value in
                    OwlRowView(title: key, value: value)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK:  Form Data Section

    var formDataFieldsSection: some View {
        Group {
            if let fields = call.request?.formDataFields, !fields.isEmpty {
                DisclosureGroup("Form Data Fields") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(fields, id: \.name) { field in
                            OwlRowView(title: field.name, value: field.value)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK:  Form Data File Section

    var formDataFilesSection: some View {
        Group {
            if let files = call.request?.formDataFiles, !files.isEmpty {
                DisclosureGroup("Form Data Files") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(files, id: \.fileName) { file in
                            OwlRowView(
                                title: file.fileName,
                                value: file.contentType
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}
