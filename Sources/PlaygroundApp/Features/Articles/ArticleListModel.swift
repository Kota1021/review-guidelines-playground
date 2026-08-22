import Foundation
import Observation

@Observable
@MainActor
final class ArticleListModel {
    /// One property holds the whole load state — there is no second flag to keep in sync.
    private(set) var state: LoadState<[Article]> = .idle

    private let api: APIClient

    /// The dependency is explicit, so a test can pass a different client.
    init(api: APIClient) {
        self.api = api
    }

    func load() async {
        state = .loading
        do {
            let articles = try await api.get("articles", as: [ArticleResponse].self)
            state = .loaded(articles.compactMap(Article.init(response:)))
        } catch let failure as LoadFailure {
            state = .failed(failure)
        } catch {
            state = .failed(.decoding(underlying: error))
        }
    }
}

struct ArticleResponse: Decodable {
    let id: String
    let title: String
    let publishedAt: Date
    let category: String
}

private extension Article {
    /// A fallible conversion that refuses to build an invalid value, rather than
    /// substituting a default and letting it flow downstream.
    init?(response: ArticleResponse) {
        guard let category = Category(wireValue: response.category) else { return nil }
        self.init(
            id: ID(rawValue: response.id),
            title: response.title,
            publishedAt: response.publishedAt,
            category: category
        )
    }
}
