//
//  OwlHTTPError
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// The type of network error.
public enum OwlNetworkErrorType {
    /// The device is offline.
    case offline
    /// The request timed out.
    case timeout
    /// The request was cancelled.
    case cancelled
    /// The DNS lookup failed.
    case dnsFailure
    /// The URL is invalid.
    case badURL
    /// The error is unknown.
    case unknown
}

/// Represents an HTTP error.
public struct OwlHTTPError: Sendable, Equatable {
    /// The error.
    public let error: any Error & Sendable
    /// The stack trace of the error.
    public let stackTrace: String?
    /// The code of the error.
    public let code: Int?

    /// Creates a new HTTP error.
    public init(
        error: any Error,
        stackTrace: String? = nil,
        code: Int? = nil
    ) {
        self.error = error
        self.stackTrace = stackTrace
        self.code = code
    }

    /// The resolved code of the error.
    public var resolvedCode: Int? {
        if let code {
            return code
        }

        return (error as NSError).code
    }

    /// The type of network error.
    public var networkType: OwlNetworkErrorType {
        guard let urlError = error as? URLError else {
            return .unknown
        }

        switch urlError.code {
            case .notConnectedToInternet:
                return .offline

            case .timedOut:
                return .timeout

            case .cancelled:
                return .cancelled

            case .cannotFindHost,
                 .dnsLookupFailed:
                return .dnsFailure

            case .badURL:
                return .badURL

            default:
                return .unknown
        }
    }

    /// Short display string (untuk badge / status label)
    public var displayTitle: String {
        switch networkType {
            case .offline: return "OFFLINE"
            case .timeout: return "TIMEOUT"
            case .cancelled: return "CANCELLED"
            case .dnsFailure: return "DNS ERROR"
            case .badURL: return "BAD URL"
            case .unknown: return "ERROR"
        }
    }

    /// The description of the error.
    public var description: String {
        error.localizedDescription
    }

    /// Returns a copy of the error with the specified properties replaced.
    public func copy(
        error: (any Error)? = nil,
        stackTrace: String? = nil,
        code: Int? = nil
    ) -> OwlHTTPError {
        OwlHTTPError(
            error: error ?? self.error,
            stackTrace: stackTrace ?? self.stackTrace,
            code: code ?? self.code
        )
    }

    /// Returns true if the error is equal to the specified error.
    public static func == (lhs: OwlHTTPError, rhs: OwlHTTPError) -> Bool {
        lhs.error.localizedDescription == rhs.error.localizedDescription &&
            lhs.stackTrace == rhs.stackTrace &&
            lhs.resolvedCode == rhs.resolvedCode
    }
}
