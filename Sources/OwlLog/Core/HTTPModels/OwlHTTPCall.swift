//
//  OwlHTTPCall
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlHTTPCall: Sendable, Equatable, Identifiable {
    public let id: String
    public let createdTime: Date
    public let client: String
    public let loading: Bool
    public let secure: Bool
    public let method: String
    public let endpoint: String
    public let server: String
    public let uri: String
    public let duration: Int

    public let request: OwlHTTPRequest?
    public let response: OwlHTTPResponse?
    public let error: OwlHTTPError?

    public init(
        id: String,
        createdTime: Date = Date(),
        client: String = "",
        loading: Bool = true,
        secure: Bool = false,
        method: String = "",
        endpoint: String = "",
        server: String = "",
        uri: String = "",
        duration: Int = 0,
        request: OwlHTTPRequest? = nil,
        response: OwlHTTPResponse? = nil,
        error: OwlHTTPError? = nil
    ) {
        self.id = id
        self.createdTime = createdTime
        self.client = client
        self.loading = loading
        self.secure = secure
        self.method = method
        self.endpoint = endpoint
        self.server = server
        self.uri = uri
        self.duration = duration
        self.request = request
        self.response = response
        self.error = error
    }

    public func copy(
        id: String? = nil,
        createdTime: Date? = nil,
        client: String? = nil,
        loading: Bool? = nil,
        secure: Bool? = nil,
        method: String? = nil,
        endpoint: String? = nil,
        server: String? = nil,
        uri: String? = nil,
        duration: Int? = nil,
        request: OwlHTTPRequest? = nil,
        response: OwlHTTPResponse? = nil,
        error: OwlHTTPError? = nil
    ) -> OwlHTTPCall {
        OwlHTTPCall(
            id: id ?? self.id,
            createdTime: createdTime ?? self.createdTime,
            client: client ?? self.client,
            loading: loading ?? self.loading,
            secure: secure ?? self.secure,
            method: method ?? self.method,
            endpoint: endpoint ?? self.endpoint,
            server: server ?? self.server,
            uri: uri ?? self.uri,
            duration: duration ?? self.duration,
            request: request ?? self.request,
            response: response ?? self.response,
            error: error ?? self.error
        )
    }
}
