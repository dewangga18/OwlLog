//
//  OwlHTTPFormDataFile
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// Represents a file in form data.
public struct OwlHTTPFormDataFile: Sendable, Equatable {
    /// The length of the file.
    public let length: Int
    /// The name of the file.
    public let fileName: String
    /// The content type of the file.
    public let contentType: String
}

