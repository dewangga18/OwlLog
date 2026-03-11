//
//  OwlHTTPRequest
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// Represents an HTTP request.
public struct OwlHTTPRequest: Sendable, Equatable {
    /// The size of the request.
    public let size: Int
    /// The time when the request was created.
    public let time: Date
    /// The headers of the request.
    public let headers: [String: String]
    /// The body of the request.
    public let body: Data?
    /// The content type of the request.
    public let contentType: String?
    /// The curl command of the request.
    public let curl: String
    /// The cookies of the request.
    public let cookies: [HTTPCookie]
    /// The query parameters of the request.
    public let queryParameters: [String: String]
    /// The form data files of the request.
    public let formDataFiles: [OwlHTTPFormDataFile]?
    /// The form data fields of the request.
    public let formDataFields: [OwlFormDataField]?

    /// Returns the headers of the request sorted by key.
    public var sortedHeaders: [(key: String, value: String)] {
        headers.sorted(by: { $0.key < $1.key })
    }

    /// Creates a new HTTP request.
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

    /// Returns a copy of the request with the specified properties replaced.
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

    /// Returns true if the request is equal to the specified request.
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
