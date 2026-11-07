import Foundation

nonisolated enum RequestPolicy {
    static func fresh(_ original: URLRequest) -> URLRequest {
        var request = original
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache, no-store, max-age=0", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        return request
    }

    static func configuration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.waitsForConnectivity = false
        return configuration
    }
}

nonisolated protocol EntryFetching: Sendable {
    func fetch(_ parameters: EntryParameters) async throws -> SavedEntry?
}

nonisolated enum EntryRequestError: Error {
    case unexpectedResponse
}

nonisolated final class EntryTransport: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard request.url?.scheme?.lowercased() == "https" else { completionHandler(nil); return }
        completionHandler(RequestPolicy.fresh(request))
    }
}

nonisolated struct EntryClient: EntryFetching {
    private let session: URLSession

    init(session: URLSession? = nil) {
        self.session = session ?? URLSession(configuration: RequestPolicy.configuration(), delegate: EntryTransport(), delegateQueue: nil)
    }

    static func request(for parameters: EntryParameters) -> URLRequest {
        var components = URLComponents(string: "https://privacytextodin.top/json/get.php")!
        components.percentEncodedQuery = "token=" + parameters.encodedPayload
        var request = URLRequest(url: components.url!, timeoutInterval: 15)
        request.httpMethod = "GET"
        return RequestPolicy.fresh(request)
    }

    func fetch(_ parameters: EntryParameters) async throws -> SavedEntry? {
        let (data, response) = try await session.data(for: Self.request(for: parameters))
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw EntryRequestError.unexpectedResponse
        }
        return SavedEntry.parse(data)
    }
}
