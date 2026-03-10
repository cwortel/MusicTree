import Foundation

/// Merges results from Discogs and MusicBrainz, deduplicating by name similarity
enum SearchMerger {

    // MARK: - Artists

    static func mergeArtists(discogs: [Artist], musicBrainz: [Artist]) -> [Artist] {
        var merged: [Artist] = []
        var usedMBIndices = Set<Int>()

        for dArtist in discogs {
            if let mbIndex = musicBrainz.firstIndex(where: { namesMatch($0.name, dArtist.name) }),
               !usedMBIndices.contains(mbIndex) {
                usedMBIndices.insert(mbIndex)
                let mbArtist = musicBrainz[mbIndex]
                // Merge: prefer Discogs image, MusicBrainz disambiguation
                let mergedArtist = Artist(
                    id: dArtist.id,
                    name: dArtist.name,
                    sortName: mbArtist.sortName ?? dArtist.sortName,
                    disambiguation: mbArtist.disambiguation ?? dArtist.disambiguation,
                    profile: dArtist.profile,
                    imageURL: dArtist.imageURL ?? mbArtist.imageURL,
                    urls: dArtist.urls,
                    discogsID: dArtist.discogsID,
                    musicBrainzID: mbArtist.musicBrainzID,
                    sources: [.discogs, .musicBrainz]
                )
                merged.append(mergedArtist)
            } else {
                merged.append(dArtist)
            }
        }

        // Add unmatched MusicBrainz artists
        for (index, mbArtist) in musicBrainz.enumerated() where !usedMBIndices.contains(index) {
            merged.append(mbArtist)
        }

        return merged
    }

    // MARK: - Albums

    static func mergeAlbums(discogs: [Album], musicBrainz: [Album]) -> [Album] {
        var merged: [Album] = []
        var usedMBIndices = Set<Int>()

        for dAlbum in discogs {
            if let mbIndex = musicBrainz.firstIndex(where: { albumsMatch($0, dAlbum) }),
               !usedMBIndices.contains(mbIndex) {
                usedMBIndices.insert(mbIndex)
                let mbAlbum = musicBrainz[mbIndex]
                let mergedAlbum = Album(
                    id: dAlbum.id,
                    title: dAlbum.title,
                    artistName: dAlbum.artistName.isEmpty ? mbAlbum.artistName : dAlbum.artistName,
                    year: dAlbum.year ?? mbAlbum.year,
                    genres: dAlbum.genres ?? mbAlbum.genres,
                    styles: dAlbum.styles,
                    coverImageURL: dAlbum.coverImageURL ?? mbAlbum.coverImageURL,
                    tracklist: dAlbum.tracklist ?? mbAlbum.tracklist,
                    credits: dAlbum.credits,
                    formats: dAlbum.formats,
                    country: dAlbum.country ?? mbAlbum.country,
                    labels: dAlbum.labels,
                    discogsID: dAlbum.discogsID,
                    musicBrainzID: mbAlbum.musicBrainzID,
                    sources: [.discogs, .musicBrainz]
                )
                merged.append(mergedAlbum)
            } else {
                merged.append(dAlbum)
            }
        }

        for (index, mbAlbum) in musicBrainz.enumerated() where !usedMBIndices.contains(index) {
            merged.append(mbAlbum)
        }

        return merged
    }

    // MARK: - Matching Helpers

    private static func namesMatch(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }

    private static func albumsMatch(_ a: Album, _ b: Album) -> Bool {
        guard namesMatch(a.title, b.title) else { return false }
        // If both have artist names, check those too
        if !a.artistName.isEmpty && !b.artistName.isEmpty {
            guard namesMatch(a.artistName, b.artistName) else { return false }
        }
        // Allow year difference of ±1 (regional release differences)
        if let ya = a.year, let yb = b.year {
            return abs(ya - yb) <= 1
        }
        return true
    }

    private static func normalize(_ string: String) -> String {
        string
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
    }
}
