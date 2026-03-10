import Foundation
import Observation

/// ViewModel for artist detail — lazy-loads sections on expand
@MainActor
@Observable
final class ArtistDetailViewModel {
    var artist: Artist
    var isLoading = false
    var errorMessage: String?

    // Lazy-loaded section data
    var releases: [Album]?
    var members: [Artist.Member]?

    // Loading state per section
    var isLoadingReleases = false
    var isLoadingMembers = false

    private let discogs = DiscogsService()
    private let musicBrainz = MusicBrainzService()

    init(artist: Artist) {
        self.artist = artist
    }

    /// Load the basic artist detail (profile, links)
    func loadDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            // Prefer Discogs for profile/bio
            if let discogsID = artist.discogsID {
                let detailed = try await discogs.getArtist(id: discogsID)
                artist = Artist(
                    id: artist.id,
                    name: detailed.name,
                    sortName: detailed.sortName ?? artist.sortName,
                    disambiguation: artist.disambiguation ?? detailed.disambiguation,
                    profile: detailed.profile,
                    imageURL: detailed.imageURL ?? artist.imageURL,
                    urls: detailed.urls ?? artist.urls,
                    discogsID: artist.discogsID,
                    musicBrainzID: artist.musicBrainzID,
                    sources: artist.sources
                )
            } else if let mbid = artist.musicBrainzID {
                let detailed = try await musicBrainz.getArtist(mbid: mbid)
                artist = Artist(
                    id: artist.id,
                    name: detailed.name,
                    sortName: detailed.sortName ?? artist.sortName,
                    disambiguation: detailed.disambiguation ?? artist.disambiguation,
                    profile: detailed.profile,
                    imageURL: artist.imageURL,
                    urls: detailed.urls ?? artist.urls,
                    discogsID: artist.discogsID,
                    musicBrainzID: artist.musicBrainzID,
                    sources: artist.sources
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Lazy-load releases when the section is expanded
    func loadReleasesIfNeeded() async {
        guard releases == nil, !isLoadingReleases else { return }
        isLoadingReleases = true

        do {
            var allReleases: [Album] = []

            if let discogsID = artist.discogsID {
                let dReleases = try await discogs.getArtistReleases(id: discogsID)
                allReleases.append(contentsOf: dReleases)
            }

            if let mbid = artist.musicBrainzID {
                let mbReleases = try await musicBrainz.getArtistReleaseGroups(mbid: mbid)
                if allReleases.isEmpty {
                    allReleases = mbReleases
                } else {
                    allReleases = SearchMerger.mergeAlbums(discogs: allReleases, musicBrainz: mbReleases)
                }
            }

            releases = allReleases
        } catch {
            releases = []
        }

        isLoadingReleases = false
    }

    /// Lazy-load band members when the section is expanded
    func loadMembersIfNeeded() async {
        guard members == nil, !isLoadingMembers else { return }
        isLoadingMembers = true

        do {
            if let mbid = artist.musicBrainzID {
                members = try await musicBrainz.getArtistMembers(mbid: mbid)
            } else {
                members = []
            }
        } catch {
            members = []
        }

        isLoadingMembers = false
    }
}
