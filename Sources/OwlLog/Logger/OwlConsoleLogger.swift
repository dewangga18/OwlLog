//
//  OwlConsoleLogger
//  OwlLog
//
//  Created by aaronevanjulio on 06/08/26.
//

import Foundation

/// Shared internal console logger.
///
/// Gates SDK debug output behind #if DEBUG and uses a uniform [OwlLog] prefix.
/// `package` keeps the helper visible across OwlLog and OwlLogUI targets while
/// hiding it from host apps.
package enum OwlConsoleLogger {
    package static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[OwlLog] \(message())")
        #endif
    }
}
