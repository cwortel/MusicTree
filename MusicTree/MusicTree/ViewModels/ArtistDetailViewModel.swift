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

    /// Ordered release type categories
    static let releaseTypeOrder = ["Album", "EP", "Single", "Other"]

    /// Releases grouped by type (Album, EP, Single, Other), each sorted by year descending
    var groupedReleases: [(type: String, albums: [Album])] {
        guard let releases else { return [] }
        let dict = Dictionary(grouping: releases, by: \.releaseType)
        return Self.releaseTypeOrder.compactMap { type in
            guard let albums = dict[type], !albums.isEmpty else { return nil }
            return (type: type, albums: albums)
        }
    }

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

    /// Lazy-load releases — MusicBrainz release-groups first (clean discography),
    /// Discogs as fallback only if MB has nothing or fails.
    func loadReleasesIfNeeded() async {
        guard releases == nil, !isLoadingReleases else { return }
        isLoadingReleases = true

        // Try MusicBrainz first — release-groups give deduplicated albums
        var mbReleases: [Album] = []
        if let mbid = artist.musicBrainzID {
            do {
                mbReleases = try await musicBrainz.getArtistReleaseGroups(mbid: mbid)
            } catch {
                // MB failed, will fall back to Discogs
            }
        }

        if !mbReleases.isEmpty {
            releases = mbReleases.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        } else if let discogsID = artist.discogsID {
            // Fallback: Discogs releases (noisier but better than nothing)
            do {
                releases = try await discogs.getArtistReleases(id: discogsID)
                    .sorted { ($0.year ?? 0) > ($1.year ?? 0) }
            } catch {
                releases = []
            }
        } else {
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
