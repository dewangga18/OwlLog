//
//  OwlHTTPError
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public enum OwlNetworkErrorType {
    case offline
    case timeout
    case cancelled
    case dnsFailure
    case badURL
    case unknown
}

public struct OwlHTTPError: Sendable, Equatable {
    public let error: any Error & Sendable
    public let stackTrace: String?
    public let code: Int?

    public init(
        error: any Error,
        stackTrace: String? = nil,
        code: Int? = nil
    ) {
        self.error = error
        self.stackTrace = stackTrace
        self.code = code
    }

    public var resolvedCode: Int? {
        if let code {
            return code
        }

        return (error as NSError).code
    }

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

    public var description: String {
        error.localizedDescription
    }

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

    public static func == (lhs: OwlHTTPError, rhs: OwlHTTPError) -> Bool {
        lhs.error.localizedDescription == rhs.error.localizedDescription &&
            lhs.stackTrace == rhs.stackTrace &&
            lhs.resolvedCode == rhs.resolvedCode
    }
}
