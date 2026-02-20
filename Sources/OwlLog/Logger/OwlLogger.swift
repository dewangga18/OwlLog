//
//  OwlLogger
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public actor OwlLogger {
    public static let shared = OwlLogger()
    
    private var calls: [OwlHTTPCall] = []
    private var isInspectorOpened: Bool = false
    
    private init() {}
    
    public func allCalls() -> [OwlHTTPCall] {
        calls
    }
    
    public func clear() {
        calls.removeAll()
    }
    
    public func addCall(_ call: OwlHTTPCall) {
        calls.append(call)
    }
    
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
