//
//  OwlStats
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation
import OwlLog

struct OwlStats {
    let totalCalls: Int
    let successRate: Double
    let errorRate: Double
    let avgResponseTime: Double
    let statusCodeDistribution: [String: Int]
    let methodDistribution: [String: Int]
    let slowestEndpoints: [OwlHTTPCall]

    static func calculate(from calls: [OwlHTTPCall]) -> OwlStats {
        let totalCalls = calls.count

        var successCount = 0
        var errorCount = 0
        var totalDuration = 0

        var statusCodeDistribution: [String: Int] = [:]
        var methodDistribution: [String: Int] = [:]

        var completedCalls: [OwlHTTPCall] = []

        for call in calls {
            if let status = call.response?.status {
                let key = String(status)
                statusCodeDistribution[key, default: 0] += 1

                if status >= 200 && status < 300 {
                    successCount += 1
                } else if status >= 400 {
                    errorCount += 1
                }

                completedCalls.append(call)
            }

            if call.error != nil {
                errorCount += 1
            }

            methodDistribution[call.method, default: 0] += 1
            totalDuration += call.duration
        }

        completedCalls.sort { $0.duration > $1.duration }

        return OwlStats(
            totalCalls: totalCalls,
            successRate: totalCalls > 0 ? (Double(successCount) / Double(totalCalls)) * 100 : 0,
            errorRate: totalCalls > 0 ? (Double(errorCount) / Double(totalCalls)) * 100 : 0,
            avgResponseTime: totalCalls > 0 ? Double(totalDuration) / Double(totalCalls) : 0,
            statusCodeDistribution: statusCodeDistribution,
            methodDistribution: methodDistribution,
            slowestEndpoints: Array(completedCalls.prefix(5))
        )
    }
}
