import SwiftUI
import SwiftData

struct AlbumDetailView: View {
    @State private var viewModel: AlbumDetailViewModel
    @State private var showImageZoom = false
    @State private var showAddedConfirmation = false
    @Environment(\.modelContext) private var modelContext

    init(album: Album) {
        _viewModel = State(wrappedValue: AlbumDetailViewModel(album: album))
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

                // Add to collection button
                Button {
                    PersistenceService.addToCollection(album: viewModel.album, context: modelContext)
                    showAddedConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showAddedConfirmation = false
                    }
                } label: {
                    if showAddedConfirmation {
                        Label("Added to Collection", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Add to Collection", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(showAddedConfirmation ? .green : .accentColor)
                .disabled(showAddedConfirmation)
                .animation(.easeInOut(duration: 0.25), value: showAddedConfirmation)
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
