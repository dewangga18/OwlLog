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

        // Read body from httpBodyStream if httpBody is nil.
        // URLSession uses a stream internally for multipart/encoded bodies — draining
        // it here and replacing with raw Data keeps the body intact for both logging
        // and the actual network request.
        if mutableReq.httpBody == nil, let stream = mutableReq.httpBodyStream {
            var data = Data()
            stream.open()
            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while stream.hasBytesAvailable {
                let bytesRead = stream.read(&buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(buffer, count: bytesRead)
                } else {
                    break
                }
            }
            stream.close()
            if !data.isEmpty {
                // Replace the stream with raw Data so URLSession can still send the body
                // and we can read it for logging / curl generation below.
                mutableReq.httpBody = data
            }
        }

        let newRequest = mutableReq as URLRequest

        let id = UUID().uuidString
        let startTime = Date()

        // Parse multipart body parts when Content-Type is multipart/form-data,
        // so formDataFields and formDataFiles are populated for the UI.
        var formDataFiles: [OwlHTTPFormDataFile]? = nil
        var formDataFields: [OwlFormDataField]? = nil
        if let contentTypeHeader = newRequest.value(forHTTPHeaderField: "Content-Type"),
           contentTypeHeader.lowercased().contains("multipart/form-data"),
           let body = newRequest.httpBody
        {
            let parsed = Self.parseMultipartBody(body, contentTypeHeader: contentTypeHeader)
            formDataFiles = parsed.files.isEmpty ? nil : parsed.files
            formDataFields = parsed.fields.isEmpty ? nil : parsed.fields
        }

        let requestModel = OwlHTTPRequest(
            size: newRequest.httpBody?.count ?? 0,
            time: startTime,
            headers: newRequest.allHTTPHeaderFields ?? [:],
            body: newRequest.httpBody,
            contentType: newRequest.value(forHTTPHeaderField: "Content-Type"),
            curl: OwlCurlBuilder.generate(from: newRequest),
            queryParameters: newRequest.url?.queryParameters ?? [:],
            formDataFiles: formDataFiles,
            formDataFields: formDataFields
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

    // MARK: - Multipart Parser

    /// Result type from parsing a multipart/form-data body.
    private struct MultipartParseResult {
        var files: [OwlHTTPFormDataFile] = []
        var fields: [OwlFormDataField] = []
    }

    /// Parses a raw `multipart/form-data` body and extracts text fields and file metadata.
    ///
    /// - Parameters:
    ///   - body: The raw request body bytes.
    ///   - contentTypeHeader: The full `Content-Type` header value, e.g.
    ///     `multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW`
    /// - Returns: A result struct with extracted `files` and `fields`.
    private static func parseMultipartBody(
        _ body: Data,
        contentTypeHeader: String
    ) -> MultipartParseResult {
        var result = MultipartParseResult()

        // Extract boundary from Content-Type header.
        // e.g. "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
        guard let boundaryValue = contentTypeHeader
            .components(separatedBy: ";")
            .first(where: { $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("boundary=") })?
            .trimmingCharacters(in: .whitespaces)
            .dropFirst("boundary=".count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        else {
            return result
        }

        let boundary = "--" + boundaryValue
        guard let boundaryData = boundary.data(using: .utf8),
              let crlfData = "\r\n".data(using: .utf8),
              let crlfcrlfData = "\r\n\r\n".data(using: .utf8)
        else {
            return result
        }

        // Split body on boundary markers.
        let parts = body.components(separatedBy: boundaryData)

        for part in parts {
            // Skip empty parts and the final "--" epilogue.
            guard part.count > 4 else { continue }

            // Each valid part starts with CRLF (from the boundary line), then headers,
            // then CRLF CRLF separator, then the part body.
            var partData = part
            // Strip leading CRLF that follows the boundary.
            if partData.starts(with: crlfData) {
                partData = partData.dropFirst(2)
            }
            // Strip trailing CRLF before the next boundary.
            if partData.hasSuffix(crlfData) {
                partData = partData.dropLast(2)
            }
            // Skip final "--" epilogue.
            if partData.starts(with: Data([0x2D, 0x2D])) { continue } // "--"

            // Find the header/body split (first blank line: \r\n\r\n).
            guard let headerEndRange = partData.range(of: crlfcrlfData) else { continue }

            let headerData = partData[partData.startIndex ..< headerEndRange.lowerBound]
            let bodyData = partData[headerEndRange.upperBound...]

            // Parse part headers (key: value pairs, CRLF-separated).
            guard let headerString = String(data: headerData, encoding: .utf8) else { continue }
            var partHeaders: [String: String] = [:]
            for line in headerString.components(separatedBy: "\r\n") {
                let pair = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                if pair.count == 2 {
                    partHeaders[pair[0].lowercased()] = pair[1]
                }
            }

            // Content-Disposition is required.
            guard let disposition = partHeaders["content-disposition"] else { continue }

            // Extract "name" from Content-Disposition.
            let name = Self.extractDispositionParam("name", from: disposition) ?? "unknown"

            if let filename = Self.extractDispositionParam("filename", from: disposition) {
                // This part is a file upload.
                let fileContentType = partHeaders["content-type"] ?? "application/octet-stream"
                result.files.append(
                    OwlHTTPFormDataFile(
                        length: bodyData.count,
                        fileName: filename,
                        contentType: fileContentType
                    )
                )
            } else {
                // This part is a plain text field.
                let value = String(data: bodyData, encoding: .utf8) ?? ""
                result.fields.append(OwlFormDataField(name: name, value: value))
            }
        }

        return result
    }

    /// Extracts the value of a named parameter from a Content-Disposition header value.
    ///
    /// Handles both quoted values (`name="field1"`) and unquoted values (`name=field1`).
    ///
    /// - Parameters:
    ///   - param: The parameter name, e.g. `"name"` or `"filename"`.
    ///   - disposition: The full Content-Disposition value, e.g.
    ///     `form-data; name="field1"; filename="file.jpg"`
    /// - Returns: The unquoted value, or `nil` if the parameter is not present.
    private static func extractDispositionParam(_ param: String, from disposition: String) -> String? {
        // Try quoted form first: name="value"
        let quotedPattern = param + "=\""
        if let startRange = disposition.range(of: quotedPattern, options: .caseInsensitive) {
            let afterQuote = disposition[startRange.upperBound...]
            if let endQuote = afterQuote.firstIndex(of: "\"") {
                return String(afterQuote[afterQuote.startIndex ..< endQuote])
            }
        }

        // Fall back to unquoted form: name=value (terminated by ; or end of string)
        let unquotedPattern = param + "="
        if let startRange = disposition.range(of: unquotedPattern, options: .caseInsensitive) {
            let afterEquals = disposition[startRange.upperBound...]
            // Value ends at the next semicolon or end of string.
            let value: String
            if let semicolon = afterEquals.firstIndex(of: ";") {
                value = String(afterEquals[afterEquals.startIndex ..< semicolon])
            } else {
                value = String(afterEquals)
            }
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }
}

// MARK: - Data helpers (file-private, used only by OwlURLProtocol multipart parser)

private extension Data {
    /// Splits the receiver around every occurrence of `separator`, similar to `String.components(separatedBy:)`.
    func components(separatedBy separator: Data) -> [Data] {
        var parts: [Data] = []
        var searchStart = startIndex

        while let separatorRange = range(of: separator, in: searchStart ..< endIndex) {
            parts.append(self[searchStart ..< separatorRange.lowerBound])
            searchStart = separatorRange.upperBound
        }

        parts.append(self[searchStart ..< endIndex])
        return parts
    }

    /// Returns `true` if the receiver ends with the given `suffix`.
    func hasSuffix(_ suffix: Data) -> Bool {
        guard count >= suffix.count else { return false }
        return self[(endIndex - suffix.count)...] == suffix
    }
}
