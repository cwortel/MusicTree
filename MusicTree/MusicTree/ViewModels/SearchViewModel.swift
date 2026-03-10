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

        do {
            switch searchType {
            case .artists:
                async let da = discogs.searchArtists(query: trimmed)
                async let ma = musicBrainz.searchArtists(query: trimmed)
                let (discogsArtists, mbArtists) = try await (da, ma)
                artists = SearchMerger.mergeArtists(discogs: discogsArtists, musicBrainz: mbArtists)

            case .releases:
                async let dr = discogs.searchReleases(query: trimmed)
                async let mr = musicBrainz.searchReleases(query: trimmed)
                let (discogsReleases, mbReleases) = try await (dr, mr)
                albums = SearchMerger.mergeAlbums(discogs: discogsReleases, musicBrainz: mbReleases)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
