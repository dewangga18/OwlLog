//
//  OwlURLProtocol
//  OwlLog
//
//  Created by aaronevanjulio on 11/02/26.
//

import Foundation

/// A URL protocol that logs all HTTP requests and responses.
public final class OwlURLProtocol: URLProtocol {
    private var dataTask: URLSessionDataTask?

    /// Whether to log HTTP requests and responses to the console.
    public static var isConsoleLogEnabled: Bool = true

    /// Sets up the URL protocol to log all HTTP requests and responses.
    public static func setup(in config: URLSessionConfiguration, isConsoleLogEnabled: Bool = true) {
        self.isConsoleLogEnabled = isConsoleLogEnabled
        config.protocolClasses = [OwlURLProtocol.self] + (config.protocolClasses ?? [])
    }

    /// Returns true if the URL protocol can handle the specified request.
    override public class func canInit(with request: URLRequest) -> Bool {
        if URLProtocol.property(forKey: "OwlHandled", in: request) != nil {
            return false
        }
        return true
    }

    /// Returns the canonical request for the specified request.
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Starts loading the specified request.
    override public func startLoading() {
        guard let client = client else { return }

        guard let mutableReq = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }

        // Set the property to true to indicate that the request has been handled.
        URLProtocol.setProperty(true, forKey: "OwlHandled", in: mutableReq)

        let newRequest = mutableReq as URLRequest

        let id = UUID().uuidString
        let startTime = Date()

        let requestModel = OwlHTTPRequest(
            size: newRequest.httpBody?.count ?? 0,
            time: startTime,
            headers: newRequest.allHTTPHeaderFields ?? [:],
            body: newRequest.httpBody,
            contentType: newRequest.value(forHTTPHeaderField: "Content-Type"),
            curl: OwlCurlBuilder.generate(from: newRequest),
            queryParameters: newRequest.url?.queryParameters ?? [:],
        )

        let call = OwlHTTPCall(
            id: id,
            createdTime: startTime,
            client: "URLSession",
            loading: true,
            secure: newRequest.url?.scheme == "https",
            method: newRequest.httpMethod ?? "",
            endpoint: newRequest.url?.path ?? "/",
            server: newRequest.url?.host ?? "",
            uri: newRequest.url?.absoluteString ?? "",
            request: requestModel
        )

        // Add the call to the service.
        Task { @MainActor in
            OwlService.shared.addCall(call)

            if OwlURLProtocol.isConsoleLogEnabled {
                #if DEBUG
                print("[OwlLog] 🚀 \(call.method) \(call.uri)")
                #endif
            }
        }

        let session = URLSession(configuration: .default)

        dataTask = session.dataTask(with: newRequest) { data, response, error in

            let endTime = Date()
            let duration = Int(endTime.timeIntervalSince(startTime) * 1000)

            if let httpResponse = response as? HTTPURLResponse {
                let responseModel = OwlHTTPResponse(
                    status: httpResponse.statusCode,
                    size: data?.count ?? 0,
                    time: endTime,
                    body: data,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:]
                )

                Task { @MainActor in
                    OwlService.shared.addResponse(
                        responseModel,
                        requestId: id,
                        duration: duration
                    )

                    if OwlURLProtocol.isConsoleLogEnabled {
                        let statusIcon = (200 ... 299).contains(httpResponse.statusCode) ? "✅" : "⚠️"
                        #if DEBUG
                        print("[OwlLog] \(statusIcon) \(httpResponse.statusCode) (\(duration)ms) \(newRequest.httpMethod ?? "") \(newRequest.url?.absoluteString ?? "")")
                        #endif
                    }
                }
            }

            if let error = error {
                let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
                var errorModel = OwlHTTPError(
                    error: error,
                    stackTrace: stackTrace
                )

                if let error = error as? URLError {
                    errorModel = errorModel.copy(code: error.errorCode)
                }

                Task { @MainActor in
                    OwlService.shared.addError(
                        errorModel,
                        requestId: id,
                        duration: duration
                    )

                    if OwlURLProtocol.isConsoleLogEnabled {
                        #if DEBUG
                        print("[OwlLog] ❌ ERROR (\(duration)ms) \(newRequest.httpMethod ?? "") \(newRequest.url?.absoluteString ?? "")")
                        print("        Reason: \(error.localizedDescription)")
                        #endif
                    }
                }
            }

            if let response = response {
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = data {
                client.urlProtocol(self, didLoad: data)
            }

            if let error = error {
                client.urlProtocol(self, didFailWithError: error)
            } else {
                client.urlProtocolDidFinishLoading(self)
            }
        }

        dataTask?.resume()
    }

    /// Stops loading the specified request.
    override public func stopLoading() {
        dataTask?.cancel()
    }
}
