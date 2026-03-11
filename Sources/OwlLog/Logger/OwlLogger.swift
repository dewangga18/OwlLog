//
//  OwlLogger
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A logger that logs all HTTP requests and responses.
public actor OwlLogger {
    /// The shared instance of the logger.
    public static let shared = OwlLogger()
    
    /// All HTTP calls.
    private var calls: [OwlHTTPCall] = []
    
    /// Flag to check if the inspector is opened.
    private var isInspectorOpened: Bool = false
    
    private init() {}
    
    /// Returns all HTTP calls.
    public func allCalls() -> [OwlHTTPCall] {
        calls
    }
    
    /// Clears all HTTP calls.
    public func clear() {
        calls.removeAll()
    }
    
    /// Adds an HTTP call to the logger.
    public func addCall(_ call: OwlHTTPCall) {
        calls.append(call)
    }
    
    /// Adds an HTTP response to the logger.
    public func addResponse(_ response: OwlHTTPResponse, requestId: String) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            #if DEBUG
            print("⚠️ No call found with id \(requestId)")
            #endif
            return
        }
        
        let seed = calls[index]
        let duration = Int(
            response.time.timeIntervalSince(seed.createdTime) * 1000
        )
        
        calls[index] = seed.copy(
            duration: duration, response: response
        )
    }
    
    /// Adds an HTTP error to the logger.
    public func addError(_ error: OwlHTTPError, requestId: String) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            #if DEBUG
            print("⚠️ No call found with id \(requestId)")
            #endif
            return
        }
        
        let seed = calls[index]
        let duration = Int(
            Date().timeIntervalSince(seed.createdTime) * 1000
        )
        
        calls[index] = seed.copy(
            duration: duration, error: error
        )
    }
}
