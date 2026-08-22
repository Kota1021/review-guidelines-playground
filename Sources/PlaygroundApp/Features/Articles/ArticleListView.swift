import SwiftUI

struct ArticleListView: View {
    @State private var model: ArticleListModel

    init(model: ArticleListModel) {
        _model = State(wrappedValue: model)
    }

    var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                ProgressView()
            case let .loaded(articles):
                List(articles) { article in
                    ArticleRow(article: article)
                }
            case let .failed(failure):
                FailureView(failure: failure)
            }
        }
        .task { await model.load() }
    }
}

struct ArticleRow: View {
    let article: Article

    /// Derived display is computed, not stored as a second source of truth.
    private var publishedText: String {
        article.publishedAt.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(article.title)
            Text(publishedText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct FailureView: View {
    let failure: LoadFailure

    var body: some View {
        switch failure {
        case .offline:
            ContentUnavailableView("オフラインです", systemImage: "wifi.slash")
        case let .server(status):
            ContentUnavailableView("サーバーエラー (\(status))", systemImage: "exclamationmark.icloud")
        case .decoding:
            ContentUnavailableView("データを読み込めませんでした", systemImage: "doc.questionmark")
        }
    }
}
