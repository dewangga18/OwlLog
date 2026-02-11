//
//  OwlHTTPError
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlHTTPError: Sendable, Equatable {
    public let error: any Error & Sendable
    public let stackTrace: String?

    public init(
        error: any Error,
        stackTrace: String? = nil
    ) {
        self.error = error
        self.stackTrace = stackTrace
    }

    public func copy(
        error: (any Error)? = nil,
        stackTrace: String? = nil
    ) -> OwlHTTPError {
        OwlHTTPError(
            error: error ?? self.error,
            stackTrace: stackTrace ?? self.stackTrace
        )
    }

    public static func == (lhs: OwlHTTPError, rhs: OwlHTTPError) -> Bool {
        lhs.error.localizedDescription == rhs.error.localizedDescription &&
            lhs.stackTrace == rhs.stackTrace
    }
}
