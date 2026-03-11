import SwiftUI
import SwiftData

struct AlbumDetailView: View {
    @State private var viewModel: AlbumDetailViewModel
    @State private var showImageZoom = false
    @Query private var collectionItems: [CollectionItem]
    @Environment(\.modelContext) private var modelContext

    private var inCollection: Bool { !collectionItems.isEmpty }

    init(album: Album) {
        _viewModel = State(wrappedValue: AlbumDetailViewModel(album: album))
        let albumID: String? = album.id
        _collectionItems = Query(filter: #Predicate<CollectionItem> { item in
            item.sourceID == albumID
        })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: viewModel.album.coverImageURL.flatMap { URL(string: $0) }) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .overlay {
                                Image(systemName: "opticaldisc")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { showImageZoom = true }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.album.title)
                            .font(.title3.bold())
                        if !viewModel.album.artistName.isEmpty {
                            Text(viewModel.album.artistName)
                                .font(.subheadline)
                        }
                        if let year = viewModel.album.year {
                            Text(String(year))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let genres = viewModel.album.genres, !genres.isEmpty {
                            Text(genres.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        SourceBadge(sources: viewModel.album.sources)
                    }
                }
                .padding(.horizontal)

                // Add to / remove from collection button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if inCollection {
                            for item in collectionItems {
                                PersistenceService.delete(item, context: modelContext)
                            }
                        } else {
                            PersistenceService.addToCollection(album: viewModel.album, context: modelContext)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: inCollection ? "checkmark.circle.fill" : "plus.circle.fill")
                            .contentTransition(.symbolEffect(.replace))
                        Text(inCollection ? "In Collection" : "Add to Collection")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(inCollection ? .green : .accentColor)
                .padding(.horizontal)

                // Tracklist
                if let tracks = viewModel.album.tracklist, !tracks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tracklist")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tracks) { track in
                            HStack {
                                Text(track.position)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, alignment: .leading)
                                Text(track.title)
                                    .font(.body)
                                Spacer()
                                if let duration = track.duration {
                                    Text(duration)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Credits
                if let credits = viewModel.album.credits, !credits.isEmpty {
                    CreditListView(credits: credits)
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.album.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showImageZoom {
                ZoomableImageOverlay(
                    url: viewModel.album.coverImageURL.flatMap { URL(string: $0) },
                    onDismiss: { showImageZoom = false }
                )
            }
        }
        .task {
            await viewModel.loadDetail()
        }
    }
}
