import Foundation

struct Article: Identifiable, Equatable {
    /// A dedicated ID type, so an article id cannot be passed where some other id is expected.
    struct ID: Hashable, Codable {
        let rawValue: String
    }

    let id: ID
    let title: String
    let publishedAt: Date
    let category: Category
}

enum Category: Equatable {
    case news
    case tutorial
    case release

    /// The wire value is mapped explicitly, so renaming a case cannot silently break the
    /// API contract.
    var wireValue: String {
        switch self {
        case .news: return "news"
        case .tutorial: return "tutorial"
        case .release: return "release"
        }
    }

    init?(wireValue: String) {
        switch wireValue {
        case "news": self = .news
        case "tutorial": self = .tutorial
        case "release": self = .release
        default: return nil
        }
    }
}
