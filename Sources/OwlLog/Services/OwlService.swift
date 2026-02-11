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
    @Published public var isInspectorOpened: Bool = false
    public var urlSession: URLSession? = .shared

    public func addCall(_ call: OwlHTTPCall) {
        calls.append(call)
    }

    public func addResponse(_ response: OwlHTTPResponse, requestId: Int, duration: Int) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            print("⚠️ No call found with id \(requestId)")
            return
        }

        let seed = calls[index]

        calls[index] = seed.copy(
            loading: false,
            duration: duration,
            response: response
        )
    }

    public func addError(_ error: OwlHTTPError, requestId: Int, duration: Int) {
        guard let index = calls.firstIndex(where: { $0.id == requestId }) else {
            print("⚠️ No call found with id \(requestId)")
            return
        }

        let seed = calls[index]

        calls[index] = seed.copy(
            loading: false,
            duration: duration,
            error: error
        )
    }

    public func clearCalls() {
        calls.removeAll()
    }

    public func openInspector() {
        guard !isInspectorOpened else { return }
        isInspectorOpened = true
    }

    public func closeInspector() {
        isInspectorOpened = false
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
