//
//  OwlHTTPFormDataFile
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlHTTPFormDataFile: Sendable, Equatable {
    public let length: Int
    public let fileName: String
    public let contentType: String
}

