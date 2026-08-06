//
//  OwlConsoleLogger
//  OwlLog
//
//  Created by aaronevanjulio on 06/08/26.
//

import Foundation

/// A shared internal logger for the OwlLog SDK.
///
/// All SDK-internal console output should go through this helper so debug logging
/// is consistently gated by `#if DEBUG` and uses a uniform `[OwlLog]` prefix.
/// `package` access keeps it visible to every target of this package (OwlLog,
/// OwlLogUI) while staying hidden from host apps.
package enum OwlConsoleLogger {
    package static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[OwlLog] \(message())")
        #endif
    }
}
