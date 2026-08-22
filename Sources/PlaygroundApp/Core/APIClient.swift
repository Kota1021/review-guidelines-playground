import Foundation

/// The single place that knows how to talk to the backend.
///
/// Features depend on this; it depends on nothing in `Features/`.
struct APIClient {
    var baseURL: URL
    var session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<Response: Decodable>(_ path: String, as type: Response.Type) async throws -> Response {
        let (data, response) = try await session.data(from: baseURL.appendingPathComponent(path))

        guard let http = response as? HTTPURLResponse else {
            throw LoadFailure.offline
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LoadFailure.server(status: http.statusCode)
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            // The reason is carried, not swallowed.
            throw LoadFailure.decoding(underlying: error)
        }
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
