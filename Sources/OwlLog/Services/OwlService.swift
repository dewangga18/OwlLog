//
//  OwlService
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation
import SwiftUI

@MainActor
public final class OwlService: ObservableObject {
    public static let shared = OwlService()

    private init() {}

    @Published public private(set) var calls: [OwlHTTPCall] = []
    @Published public private(set) var stats: OwlStats = .zero
    @Published public var isInspectorOpened: Bool = false

    public var urlSession: URLSession? = .shared

    public func addCall(_ call: OwlHTTPCall) {
        calls.append(call)
        updateStats()
    }

    public func addResponse(_ response: OwlHTTPResponse, requestId: String, duration: Int) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            #if DEBUG
            print("⚠️ No call found with id \(requestId)")
            #endif
            return
        }

        let seed = calls[index]

        calls[index] = seed.copy(
            loading: false,
            duration: duration,
            response: response
        )
        updateStats()
    }

    public func addError(_ error: OwlHTTPError, requestId: String, duration: Int) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            #if DEBUG
            print("⚠️ No call found with id \(requestId)")
            #endif
            return
        }

        let seed = calls[index]

        calls[index] = seed.copy(
            loading: false,
            duration: duration,
            error: error
        )
        updateStats()
    }

    public func clearCalls() {
        calls.removeAll()
        updateStats()
    }

    public func openInspector() {
        guard !isInspectorOpened else { return }
        isInspectorOpened = true
    }

    public func filteredCalls(_ query: String) -> [OwlHTTPCall] {
        let reversed = calls.reversed()

        guard !query.isEmpty else { return Array(reversed) }
        return reversed.filter { matches($0, query: query) }
    }

    private func matches(_ call: OwlHTTPCall, query: String) -> Bool {
        let normalized = query.lowercased()

        let fields: [String?] = [
            call.method,
            call.endpoint,
            call.server,
            call.uri,
            call.response?.status.map { String($0) },
            call.error?.error.localizedDescription,
            call.error?.stackTrace
        ]

        return fields.contains {
            $0?.lowercased().contains(normalized) ?? false
        }
    }

    public func closeInspector() {
        isInspectorOpened = false
    }

    private func updateStats() {
        self.stats = OwlStats.calculate(from: calls)
    }

    public func replay(_ call: OwlHTTPCall) async throws -> (response: HTTPURLResponse, data: Data) {
        guard let session = urlSession else {
            throw NSError(
                domain: "OwlService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "URLSession is not configured"]
            )
        }

        guard let requestModel = call.request else {
            throw NSError(
                domain: "OwlService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Request is nil"]
            )
        }

        guard let url = URL(string: call.uri) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = call.method

        for (key, value) in requestModel.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = requestModel.body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        return (httpResponse, data)
    }
}
