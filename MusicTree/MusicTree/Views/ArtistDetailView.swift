import SwiftUI
import SwiftData

struct ArtistDetailView: View {
    @State private var viewModel: ArtistDetailViewModel
    @State private var releasesExpanded = false
    @State private var expandedTypes: Set<String> = ["Album"]
    @State private var membersExpanded = false
    @State private var showImageZoom = false

    init(artist: Artist) {
        _viewModel = State(wrappedValue: ArtistDetailViewModel(artist: artist))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    AsyncImage(url: viewModel.artist.imageURL.flatMap { URL(string: $0) }) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .onTapGesture { showImageZoom = true }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.artist.name)
                            .font(.title2.bold())
                        if let disambiguation = viewModel.artist.disambiguation, !disambiguation.isEmpty {
                            Text(disambiguation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        SourceBadge(sources: viewModel.artist.sources)
                    }
                }
                .padding()

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading artist info…")
                        Spacer()
                    }
                    .padding()
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // MARK: - About Section
                if let profile = viewModel.artist.profile, !profile.isEmpty {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("About", systemImage: "info.circle")
                                .font(.headline)
                            Text(profile.strippingDiscogsMarkup)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Releases Section (lazy-loaded)
                SectionCard {
                    DisclosureGroup(isExpanded: $releasesExpanded) {
                        if viewModel.isLoadingReleases {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if let _ = viewModel.releases {
                            let grouped = viewModel.groupedReleases
                            if grouped.isEmpty {
                                Text("No releases found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(grouped, id: \.type) { group in
                                    ReleaseTypeSection(
                                        type: group.type,
                                        albums: group.albums,
                                        isExpanded: Binding(
                                            get: { expandedTypes.contains(group.type) },
                                            set: { newValue in
                                                if newValue { expandedTypes.insert(group.type) }
                                                else { expandedTypes.remove(group.type) }
                                            }
                                        )
                                    )
                                }
                            }
                        }
                    } label: {
                        Label(releasesLabel, systemImage: "music.note.list")
                            .font(.headline)
                    }
                    .onChange(of: releasesExpanded) { _, expanded in
                        if expanded {
                            Task { await viewModel.loadReleasesIfNeeded() }
                        }
                    }
                }

                // MARK: - Band Members Section (lazy-loaded)
                SectionCard {
                    DisclosureGroup(isExpanded: $membersExpanded) {
                        if viewModel.isLoadingMembers {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if let members = viewModel.members {
                            if members.isEmpty {
                                Text("No member data available.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 4)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(members) { member in
                                        NavigationLink(value: member) {
                                            HStack {
                                                Image(systemName: member.active ? "person.fill" : "person")
                                                    .foregroundStyle(member.active ? .primary : .secondary)
                                                VStack(alignment: .leading) {
                                                    Text(member.name)
                                                        .font(.subheadline)
                                                    if !member.instruments.isEmpty {
                                                        Text(member.instruments.joined(separator: " \u{00B7} "))
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                if !member.active {
                                                    Text("past")
                                                        .font(.caption2)
                                                        .foregroundStyle(.tertiary)
                                                }
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label(membersLabel, systemImage: "person.3")
                            .font(.headline)
                    }
                    .onChange(of: membersExpanded) { _, expanded in
                        if expanded {
                            Task { await viewModel.loadMembersIfNeeded() }
                        }
                    }
                }

                // MARK: - Links Section
                if let urls = viewModel.artist.urls, !urls.isEmpty {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Links", systemImage: "link")
                                .font(.headline)
                            ForEach(urls, id: \.self) { urlString in
                                if let url = URL(string: urlString) {
                                    Link(urlString, destination: url)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Album.self) { album in
            AlbumDetailView(album: album)
        }
        .navigationDestination(for: Artist.Member.self) { member in
            ArtistDetailView(artist: Artist(
                id: member.musicBrainzID.map { "mb-\($0)" } ?? member.name,
                name: member.name,
                sortName: nil,
                disambiguation: nil,
                profile: nil,
                imageURL: nil,
                urls: nil,
                discogsID: nil,
                musicBrainzID: member.musicBrainzID,
                sources: member.musicBrainzID != nil ? [.musicBrainz] : []
            ))
        }
        .overlay {
            if showImageZoom {
                ZoomableImageOverlay(
                    url: viewModel.artist.imageURL.flatMap { URL(string: $0) },
                    onDismiss: { showImageZoom = false }
                )
            }
        }
        .task {
            await viewModel.loadDetail()
        }
    }

    private var releasesLabel: String {
        if let count = viewModel.releases?.count {
            return "Releases (\(count))"
        }
        return "Releases"
    }

    private var membersLabel: String {
        if let count = viewModel.members?.count {
            return "Members (\(count))"
        }
        return "Members"
    }
}

// MARK: - Release Type Sub-section

private struct ReleaseTypeSection: View {
    let type: String
    let albums: [Album]
    @Binding var isExpanded: Bool

    private var icon: String {
        switch type {
        case "Album": return "opticaldisc"
        case "EP": return "opticaldisc.fill"
        case "Single": return "music.note"
        default: return "music.quarternote.3"
        }
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(albums) { album in
                    ReleaseRow(album: album)
                }
            }
        } label: {
            Label("\(type)s (\(albums.count))", systemImage: icon)
                .font(.subheadline.weight(.medium))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Release Row with quick-add button

private struct ReleaseRow: View {
    let album: Album
    @Environment(\.modelContext) private var modelContext
    @Query private var collectionItems: [CollectionItem]

    init(album: Album) {
        self.album = album
        let albumID: String? = album.id
        _collectionItems = Query(filter: #Predicate<CollectionItem> { item in
            item.sourceID == albumID
        })
    }

    private var inCollection: Bool { !collectionItems.isEmpty }

    var body: some View {
        HStack(spacing: 0) {
            NavigationLink(value: album) {
                releaseLabel
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if inCollection {
                        for item in collectionItems {
                            PersistenceService.delete(item, context: modelContext)
                        }
                    } else {
                        PersistenceService.addToCollection(album: album, context: modelContext)
                    }
                }
            } label: {
                Image(systemName: inCollection ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(inCollection ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
    }

    private var releaseLabel: some View {
        HStack(spacing: 10) {
            AsyncImage(url: album.coverImageURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "opticaldisc")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let year = album.year {
                    Text(String(year))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

/// Reusable card wrapper for sections
struct SectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.vertical, 4)
    }
}
