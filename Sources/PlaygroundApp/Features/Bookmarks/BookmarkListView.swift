import SwiftUI

struct BookmarkListView: View {
    @State private var store: BookmarkStore
    @State private var limitText: String
    @State private var isShowingLimitEditor = false

    init(store: BookmarkStore, initialLimitText: String) {
        _store = State(wrappedValue: store)
        _limitText = State(wrappedValue: initialLimitText)
    }

    var body: some View {
        VStack {
            if store.isLoading {
                ProgressView()
            }

            if let message = store.errorMessage {
                Text(message).foregroundStyle(.red)
            }

            Text("\(store.bookmarkCount) 件のブックマーク")
                .font(.caption)

            List(store.items ?? []) { item in
                BookmarkRow(
                    item: item,
                    onTap: { print("tapped \(item.id)") }
                )
            }

            TextField("上限", text: $limitText)
                .onSubmit {
                    if Int(limitText) != nil, Int(limitText)! > 0 {
                        store.setLimit(from: limitText)
                    }
                }
        }
        .task { await store.refresh() }
    }
}

struct BookmarkRow: View {
    let item: BookmarkItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text(item.title)
                Text(item.createdDt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
