//
//  OwlStats.swift
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

public struct OwlStats: Sendable {
    public let totalCalls: Int
    public let successRate: Double
    public let errorRate: Double
    public let avgResponseTime: Double
    public let statusCodeDistribution: [String: Int]
    public let methodDistribution: [String: Int]
    public let slowestEndpoints: [OwlHTTPCall]

    public init(
        totalCalls: Int,
        successRate: Double,
        errorRate: Double,
        avgResponseTime: Double,
        statusCodeDistribution: [String: Int],
        methodDistribution: [String: Int],
        slowestEndpoints: [OwlHTTPCall]
    ) {
        self.totalCalls = totalCalls
        self.successRate = successRate
        self.errorRate = errorRate
        self.avgResponseTime = avgResponseTime
        self.statusCodeDistribution = statusCodeDistribution
        self.methodDistribution = methodDistribution
        self.slowestEndpoints = slowestEndpoints
    }

    public static func calculate(from calls: [OwlHTTPCall]) -> OwlStats {
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
