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

        do {
            // Prefer Discogs for credits
            if let discogsID = album.discogsID {
                album = try await discogs.getRelease(id: discogsID)
            } else if let mbid = album.musicBrainzID {
                album = try await musicBrainz.getRelease(mbid: mbid)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
