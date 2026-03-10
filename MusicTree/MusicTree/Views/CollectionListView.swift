import SwiftUI
import SwiftData

struct CollectionListView: View {
    @Query(sort: \CollectionItem.dateAdded, order: .reverse) private var items: [CollectionItem]
    @State private var viewModel = CollectionViewModel()
    @Environment(\.modelContext) private var modelContext

    var filteredItems: [CollectionItem] {
        if viewModel.searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.albumTitle.localizedCaseInsensitiveContains(viewModel.searchText) ||
            item.artistName.localizedCaseInsensitiveContains(viewModel.searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Collection Items",
                        systemImage: "music.note.list",
                        description: Text("Search for albums and add them to your collection.")
                    )
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink {
                                CollectionDetailView(item: item)
                            } label: {
                                CollectionItemRow(item: item)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteItem(filteredItems[index], context: modelContext)
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Filter collection…")
                }
            }
            .navigationTitle("Collection")
        }
    }
}

struct CollectionItemRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "opticaldisc")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading) {
                Text(item.albumTitle)
                    .font(.headline)
                Text(item.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let year = item.year {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
