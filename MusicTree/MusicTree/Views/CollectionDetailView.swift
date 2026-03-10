import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Bindable var item: CollectionItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    AsyncImage(url: item.coverImageURL.flatMap { URL(string: $0) }) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "opticaldisc")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            Section("Details") {
                LabeledContent("Artist", value: item.artistName)
                LabeledContent("Album", value: item.albumTitle)
                if let year = item.year {
                    LabeledContent("Year", value: String(year))
                }
                if !item.genres.isEmpty {
                    LabeledContent("Genres", value: item.genres.joined(separator: ", "))
                }
                LabeledContent("Added", value: item.dateAdded.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Notes") {
                TextEditor(text: $item.notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(item.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
