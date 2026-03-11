import Foundation
import Observation

/// ViewModel for the main search screen — queries both Discogs and MusicBrainz
@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var searchType: SearchType = .artists
    var artists: [Artist] = []
    var albums: [Album] = []
    var isLoading = false
    var errorMessage: String?

    private let discogs = DiscogsService()
    private let musicBrainz = MusicBrainzService()

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        artists = []
        albums = []

        switch searchType {
        case .artists:
            async let da = { try await discogs.searchArtists(query: trimmed) }()
            async let ma = { try await musicBrainz.searchArtists(query: trimmed) }()
            let discogsArtists = (try? await da) ?? []
            let mbArtists = (try? await ma) ?? []
            artists = SearchMerger.mergeArtists(discogs: discogsArtists, musicBrainz: mbArtists)

        case .releases:
            async let dr = { try await discogs.searchReleases(query: trimmed) }()
            async let mr = { try await musicBrainz.searchReleases(query: trimmed) }()
            let discogsReleases = (try? await dr) ?? []
            let mbReleases = (try? await mr) ?? []
            albums = SearchMerger.mergeAlbums(discogs: discogsReleases, musicBrainz: mbReleases)
        }

        isLoading = false
    }
}
