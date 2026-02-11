//
//  OwlHTTPRequest
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlHTTPRequest: Sendable, Equatable {
    public let size: Int
    public let time: Date
    public let headers: [String: String]
    public let body: Data?
    public let contentType: String?
    public let curl: String
    public let cookies: [HTTPCookie]
    public let queryParameters: [String: String]
    public let formDataFiles: [OwlHTTPFormDataFile]?
    public let formDataFields: [OwlFormDataField]?

    public var sortedHeaders: [(key: String, value: String)] {
        headers.sorted(by: { $0.key < $1.key })
    }

    public init(
        size: Int = 0,
        time: Date = Date(),
        headers: [String: String] = [:],
        body: Data? = nil,
        contentType: String? = nil,
        curl: String = "",
        cookies: [HTTPCookie] = [],
        queryParameters: [String: String] = [:],
        formDataFiles: [OwlHTTPFormDataFile]? = nil,
        formDataFields: [OwlFormDataField]? = nil
    ) {
        self.size = size
        self.time = time
        self.headers = headers
        self.body = body
        self.contentType = contentType
        self.curl = curl
        self.cookies = cookies
        self.queryParameters = queryParameters
        self.formDataFiles = formDataFiles
        self.formDataFields = formDataFields
    }

    public func copy(
        size: Int? = nil,
        time: Date? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        contentType: String? = nil,
        curl: String? = nil,
        cookies: [HTTPCookie]? = nil,
        queryParameters: [String: String]? = nil,
        formDataFiles: [OwlHTTPFormDataFile]? = nil,
        formDataFields: [OwlFormDataField]? = nil
    ) -> OwlHTTPRequest {
        OwlHTTPRequest(
            size: size ?? self.size,
            time: time ?? self.time,
            headers: headers ?? self.headers,
            body: body ?? self.body,
            contentType: contentType ?? self.contentType,
            curl: curl ?? self.curl,
            cookies: cookies ?? self.cookies,
            queryParameters: queryParameters ?? self.queryParameters,
            formDataFiles: formDataFiles ?? self.formDataFiles,
            formDataFields: formDataFields ?? self.formDataFields
        )
    }

    public static func == (lhs: OwlHTTPRequest, rhs: OwlHTTPRequest) -> Bool {
        lhs.size == rhs.size &&
            lhs.time == rhs.time &&
            lhs.headers == rhs.headers &&
            lhs.body == rhs.body &&
            lhs.contentType == rhs.contentType &&
            lhs.curl == rhs.curl &&
            lhs.cookies == rhs.cookies &&
            lhs.queryParameters == rhs.queryParameters &&
            lhs.formDataFiles == rhs.formDataFiles &&
            lhs.formDataFields == rhs.formDataFields
    }
}
