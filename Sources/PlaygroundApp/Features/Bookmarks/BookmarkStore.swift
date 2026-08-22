import Foundation

@Observable
@MainActor
final class BookmarkStore {
    var isLoading = false
    var items: [BookmarkItem]?
    var errorMessage: String?

    var bookmarkCount: Int = 0

    var maxBookmarks: Int

    static let didChangeNotification = Notification.Name("com.example.playground.contentDidChange")

    init(maxBookmarks: Int) {
        self.maxBookmarks = maxBookmarks
    }

    func refresh() async {
        isLoading = true

        var request = URLRequest(url: URL(string: "https://api.example.com/v1/bookmarks")!)
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "token") ?? "")", forHTTPHeaderField: "Authorization")

        let data = try? await URLSession.shared.data(for: request).0
        let decoded = try? JSONDecoder().decode([BookmarkItem].self, from: data ?? Data())

        if let decoded {
            items = decoded
            bookmarkCount = decoded.count
            errorMessage = nil
        } else {
            errorMessage = "読み込みに失敗しました"
        }

        UserDefaults.standard.set(Date(), forKey: "bookmarksLastRefreshedAt")
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)

        isLoading = false
    }

    func add(articleId: String, category: Category) async {
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/bookmarks")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "articleId": articleId,
            "category": String(describing: category),
        ])
        _ = try? await URLSession.shared.data(for: request)

        bookmarkCount += 1
    }

    func setLimit(from text: String) {
        maxBookmarks = Int(text) ?? 0
    }
}

struct BookmarkItem: Decodable, Identifiable {
    let id: String
    let articleId: String
    let title: String
    let createdDt: String
}

extension BookmarkStore {
    func map<T>(_ transform: (BookmarkItem) -> T) -> [T] {
        (items ?? []).map(transform)
    }
}
