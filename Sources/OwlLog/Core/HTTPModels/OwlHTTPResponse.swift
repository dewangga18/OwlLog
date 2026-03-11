//
//  OwlHTTPResponse
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// Represents an HTTP response.
public struct OwlHTTPResponse: Sendable, Equatable {
    /// The status of the response.
    public let status: Int?
    /// The size of the response.
    public let size: Int
    /// The time when the response was created.
    public let time: Date
    /// The body of the response.
    public let body: Data?
    /// The headers of the response.
    public let headers: [String: String]

    /// Returns the headers of the response sorted by key.
    public var sortedHeaders: [(key: String, value: String)] {
        headers.sorted(by: { $0.key < $1.key })
    }

    /// Creates a new HTTP response.
    public init(
        status: Int? = 0,
        size: Int = 0,
        time: Date = Date(),
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.status = status
        self.size = size
        self.time = time
        self.body = body
        self.headers = headers
    }

    /// Returns a copy of the response with the specified properties replaced.
    public func copy(
        status: Int? = nil,
        size: Int? = nil,
        time: Date? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) -> OwlHTTPResponse {
        OwlHTTPResponse(
            status: status ?? self.status,
            size: size ?? self.size,
            time: time ?? self.time,
            body: body ?? self.body,
            headers: headers ?? self.headers
        )
    }
}
