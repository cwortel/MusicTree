import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Bindable var item: CollectionItem
    @Environment(\.modelContext) private var modelContext
    @State private var showImageZoom = false

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
                    .onTapGesture { showImageZoom = true }
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

            if let sourceID = item.sourceID {
                Section {
                    NavigationLink {
                        AlbumDetailView(album: Album(
                            id: sourceID,
                            title: item.albumTitle,
                            artistName: item.artistName,
                            year: item.year,
                            genres: item.genres.isEmpty ? nil : item.genres,
                            styles: nil,
                            coverImageURL: item.coverImageURL,
                            tracklist: nil,
                            credits: nil,
                            formats: item.formats.isEmpty ? nil : item.formats,
                            country: nil,
                            labels: item.labels.isEmpty ? nil : item.labels,
                            discogsID: sourceID.hasPrefix("discogs-") ? Int(sourceID.dropFirst(8)) : nil,
                            musicBrainzID: sourceID.hasPrefix("mb-") ? String(sourceID.dropFirst(3)) : nil,
                            sources: sourceID.hasPrefix("mb-") ? [.musicBrainz] : [.discogs],
                            isReleaseGroup: sourceID.hasPrefix("mb-")
                        ))
                    } label: {
                        Label("View Full Release", systemImage: "music.note.list")
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $item.notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(item.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showImageZoom {
                ZoomableImageOverlay(
                    url: item.coverImageURL.flatMap { URL(string: $0) },
                    onDismiss: { showImageZoom = false }
                )
            }
        }
    }
}
