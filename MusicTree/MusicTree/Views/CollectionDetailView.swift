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
                        AlbumDetailView(album: Self.reconstructAlbum(from: item, sourceID: sourceID))
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

    /// Reconstruct an Album from a CollectionItem, correctly parsing source IDs
    private static func reconstructAlbum(from item: CollectionItem, sourceID: String) -> Album {
        let discogsID: Int?
        let discogsMasterID: Int?
        let musicBrainzID: String?
        let sources: Set<APISource>
        let isReleaseGroup: Bool

        if sourceID.hasPrefix("discogs-m") {
            // Discogs master release
            discogsID = nil
            discogsMasterID = Int(sourceID.dropFirst(9))
            musicBrainzID = nil
            sources = [.discogs]
            isReleaseGroup = false
        } else if sourceID.hasPrefix("discogs-") {
            // Discogs release
            discogsID = Int(sourceID.dropFirst(8))
            discogsMasterID = nil
            musicBrainzID = nil
            sources = [.discogs]
            isReleaseGroup = false
        } else if sourceID.hasPrefix("mb-") {
            // MusicBrainz release-group
            discogsID = nil
            discogsMasterID = nil
            musicBrainzID = String(sourceID.dropFirst(3))
            sources = [.musicBrainz]
            isReleaseGroup = true
        } else {
            discogsID = nil
            discogsMasterID = nil
            musicBrainzID = nil
            sources = []
            isReleaseGroup = false
        }

        return Album(
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
            discogsID: discogsID,
            discogsMasterID: discogsMasterID,
            musicBrainzID: musicBrainzID,
            sources: sources,
            isReleaseGroup: isReleaseGroup
        )
    }
}
