//
//  OwlHTTPResponse
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlHTTPResponse: Sendable, Equatable {
    public let status: Int?
    public let size: Int
    public let time: Date
    public let body: Data?
    public let headers: [String: String]

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
