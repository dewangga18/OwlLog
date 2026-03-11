//
//  OwlFormDataField
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// Represents a field in form data.
public struct OwlFormDataField: Sendable, Equatable {
    /// The name of the form data field.
    public let name: String
    /// The value of the form data field.
    public let value: String
}
