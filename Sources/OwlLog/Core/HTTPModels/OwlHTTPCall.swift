//
//  OwlHTTPCall
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// Represents an HTTP call.
public struct OwlHTTPCall: Sendable, Equatable, Identifiable {
    /// The unique identifier of the call.
    public let id: String
    /// The time when the call was created.
    public let createdTime: Date
    /// The client that made the call.
    public let client: String
    /// Whether the call is loading.
    public let loading: Bool
    /// Whether the call is secure.
    public let secure: Bool
    /// The HTTP method of the call.
    public let method: String
    /// The endpoint of the call.
    public let endpoint: String
    /// The server of the call.
    public let server: String
    /// The URI of the call.
    public let uri: String
    /// The duration of the call.
    public let duration: Int

    /// The request of the call.
    public let request: OwlHTTPRequest?
    /// The response of the call.
    public let response: OwlHTTPResponse?
    /// The error of the call.
    public let error: OwlHTTPError?

    /// Creates a new HTTP call.
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

    /// Returns a copy of the call with the specified properties replaced.
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
