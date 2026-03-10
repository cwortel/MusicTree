import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search type picker
                Picker("Search Type", selection: $viewModel.searchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: viewModel.searchType) {
                    if !viewModel.query.isEmpty {
                        Task { await viewModel.search() }
                    }
                }

                List {
                    if viewModel.searchType == .artists && !viewModel.artists.isEmpty {
                        ForEach(viewModel.artists) { artist in
                            NavigationLink(value: artist) {
                                ArtistRow(artist: artist)
                            }
                        }
                    }

                    if viewModel.searchType == .releases && !viewModel.albums.isEmpty {
                        ForEach(viewModel.albums) { album in
                            NavigationLink(value: album) {
                                AlbumRow(album: album)
                            }
                        }
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
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: viewModel.searchType == .artists ? "Search artists…" : "Search releases…")
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .navigationDestination(for: Artist.self) { artist in
                ArtistDetailView(artist: artist)
            }
            .navigationDestination(for: Album.self) { album in
                AlbumDetailView(album: album)
            }
        }
    }
}

// MARK: - Row Views

struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: artist.imageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(artist.name)
                    .font(.headline)
                if let disambiguation = artist.disambiguation, !disambiguation.isEmpty {
                    Text(disambiguation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            SourceBadge(sources: artist.sources)
        }
    }
}

struct AlbumRow: View {
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: album.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "opticaldisc")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.headline)
                if !album.artistName.isEmpty {
                    Text(album.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let year = album.year {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            SourceBadge(sources: album.sources)
        }
    }
}

struct SourceBadge: View {
    let sources: Set<APISource>

    var body: some View {
        HStack(spacing: 4) {
            if sources.contains(.discogs) {
                Text("D")
                    .font(.caption2.bold())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
            if sources.contains(.musicBrainz) {
                Text("MB")
                    .font(.caption2.bold())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    SearchView()
}
