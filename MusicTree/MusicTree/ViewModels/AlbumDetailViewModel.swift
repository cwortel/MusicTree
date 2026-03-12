import Foundation
import Observation

/// ViewModel for album detail — loads full release info including credits
@MainActor
@Observable
final class AlbumDetailViewModel {
    var album: Album
    var isLoading = false
    var errorMessage: String?

    private let discogs = DiscogsService()
    private let musicBrainz = MusicBrainzService()

    init(album: Album) {
        self.album = album
    }

    func loadDetail() async {
        isLoading = true
        errorMessage = nil

        let originalArtistName = album.artistName

        do {
            // Prefer Discogs for credits
            if let discogsID = album.discogsID {
                album = try await discogs.getRelease(id: discogsID)
            } else if let mbid = album.musicBrainzID {
                if album.isReleaseGroup {
                    album = try await musicBrainz.getReleaseGroupDetail(rgid: mbid)
                } else {
                    album = try await musicBrainz.getRelease(mbid: mbid)
                }
            }
            // Preserve artist name if API returned empty
            if album.artistName.isEmpty && !originalArtistName.isEmpty {
                album = Album(
                    id: album.id,
                    title: album.title,
                    artistName: originalArtistName,
                    year: album.year,
                    genres: album.genres,
                    styles: album.styles,
                    coverImageURL: album.coverImageURL,
                    tracklist: album.tracklist,
                    credits: album.credits,
                    formats: album.formats,
                    country: album.country,
                    labels: album.labels,
                    discogsID: album.discogsID,
                    musicBrainzID: album.musicBrainzID,
                    sources: album.sources
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
