import Foundation

/// Client for the MusicBrainz API
/// Docs: https://musicbrainz.org/doc/MusicBrainz_API
final class MusicBrainzService {
    private let client = NetworkClient.shared
    private let baseURL = "https://musicbrainz.org/ws/2"

    private let headers: [String: String] = [
        "User-Agent": "MusicTree/1.0 (https://github.com/musictree)",
        "Accept": "application/json"
    ]

    // MARK: - Search

    func searchArtists(query: String) async throws -> [Artist] {
        guard let url = buildURL(path: "/artist", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "25")
        ]) else { return [] }

        let response: MBBrowseArtistsResponse = try await client.get(url, headers: headers)
        return response.artists.map { artist in
            Artist(
                id: "mb-\(artist.id)",
                name: artist.name,
                sortName: artist.sortName,
                disambiguation: artist.disambiguation,
                profile: nil,
                imageURL: nil,
                urls: nil,
                discogsID: nil,
                musicBrainzID: artist.id,
                sources: [.musicBrainz]
            )
        }
    }

    func searchReleases(query: String) async throws -> [Album] {
        guard let url = buildURL(path: "/release", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "25")
        ]) else { return [] }

        let response: MBBrowseReleasesResponse = try await client.get(url, headers: headers)
        return response.releases.map { release in
            Album(
                id: "mb-\(release.id)",
                title: release.title,
                artistName: release.artistCredit?.map(\.name).joined(separator: ", ") ?? "",
                year: release.date.flatMap { Int($0.prefix(4)) },
                genres: nil,
                styles: nil,
                coverImageURL: "https://coverartarchive.org/release/\(release.id)/front-250",
                tracklist: nil,
                credits: nil,
                formats: nil,
                country: release.country,
                labels: nil,
                discogsID: nil,
                musicBrainzID: release.id,
                sources: [.musicBrainz]
            )
        }
    }

    // MARK: - Detail

    func getArtist(mbid: String) async throws -> Artist {
        guard let url = buildURL(path: "/artist/\(mbid)", queryItems: [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "inc", value: "url-rels")
        ]) else {
            throw NetworkError.invalidResponse
        }

        let response: MBArtistDetail = try await client.get(url, headers: headers)
        return Artist(
            id: "mb-\(response.id)",
            name: response.name,
            sortName: response.sortName,
            disambiguation: response.disambiguation,
            profile: response.type,
            imageURL: nil,
            urls: response.relations?.compactMap { $0.url?.resource },
            discogsID: nil,
            musicBrainzID: response.id,
            sources: [.musicBrainz]
        )
    }

    func getArtistReleaseGroups(mbid: String) async throws -> [Album] {
        guard let url = buildURL(path: "/release-group", queryItems: [
            URLQueryItem(name: "artist", value: mbid),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "type", value: "album|ep|single")
        ]) else { return [] }

        let response: MBReleaseGroupResponse = try await client.get(url, headers: headers)
        return response.releaseGroups.map { rg in
            Album(
                id: "mb-\(rg.id)",
                title: rg.title,
                artistName: "",
                year: rg.firstReleaseDate.flatMap { Int($0.prefix(4)) },
                genres: nil,
                styles: nil,
                coverImageURL: "https://coverartarchive.org/release-group/\(rg.id)/front-250",
                tracklist: nil,
                credits: nil,
                formats: rg.primaryType.map { [$0] },
                country: nil,
                labels: nil,
                discogsID: nil,
                musicBrainzID: rg.id,
                sources: [.musicBrainz]
            )
        }
    }

    func getArtistMembers(mbid: String) async throws -> [Artist.Member] {
        guard let url = buildURL(path: "/artist/\(mbid)", queryItems: [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "inc", value: "artist-rels")
        ]) else { return [] }

        let response: MBArtistWithRels = try await client.get(url, headers: headers)

        // Collect all relations per member, then pick the primary instrument
        var memberData: [String: (attributes: [String], active: Bool)] = [:]
        for rel in response.relations ?? [] {
            guard rel.type == "member of band",
                  let targetName = rel.artist?.name else { continue }
            let attrs = rel.attributes ?? []
            let active = !(rel.ended ?? false)
            if var existing = memberData[targetName] {
                existing.attributes.append(contentsOf: attrs)
                if active { existing.active = true }
                memberData[targetName] = existing
            } else {
                memberData[targetName] = (attributes: attrs, active: active)
            }
        }

        return memberData.map { name, data in
            let primary = Self.primaryInstrument(from: data.attributes)
            return Artist.Member(name: name, instrument: primary, active: data.active)
        }.sorted { $0.name < $1.name }
    }

    func getRelease(mbid: String) async throws -> Album {
        guard let url = buildURL(path: "/release/\(mbid)", queryItems: [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "inc", value: "recordings+artist-credits+artist-rels+recording-level-rels")
        ]) else {
            throw NetworkError.invalidResponse
        }

        let response: MBReleaseDetail = try await client.get(url, headers: headers)

        let tracks: [Track] = response.media?.flatMap { medium in
            medium.tracks?.map { track in
                Track(
                    position: "\(medium.position ?? 0)-\(track.position ?? 0)",
                    title: track.title ?? track.recording?.title ?? "",
                    duration: track.recording?.length.map { formatDuration($0) },
                    credits: nil
                )
            } ?? []
        } ?? []

        return Album(
            id: "mb-\(response.id)",
            title: response.title,
            artistName: response.artistCredit?.map(\.name).joined(separator: ", ") ?? "",
            year: response.date.flatMap { Int($0.prefix(4)) },
            genres: nil,
            styles: nil,
            coverImageURL: "https://coverartarchive.org/release/\(response.id)/front-500",
            tracklist: tracks,
            credits: nil,
            formats: nil,
            country: response.country,
            labels: nil,
            discogsID: nil,
            musicBrainzID: response.id,
            sources: [.musicBrainz]
        )
    }

    // MARK: - Helpers

    /// Pick the most representative instrument/role from a list of MusicBrainz attributes.
    /// Core instruments rank above secondary roles like "backing vocals".
    private static func primaryInstrument(from attributes: [String]) -> String? {
        guard !attributes.isEmpty else { return nil }
        let unique = Array(Set(attributes.map { $0.lowercased() }))
        if unique.count == 1 { return attributes.first }

        let coreKeywords = ["vocals", "guitar", "bass guitar", "drums",
                            "keyboard", "keyboards", "piano", "synthesizer",
                            "lead vocals", "bass", "lead guitar", "rhythm guitar"]
        let secondaryKeywords = ["backing vocals", "percussion", "additional",
                                 "programming", "samples"]

        // Prefer a core match
        for attr in attributes {
            let lower = attr.lowercased()
            if coreKeywords.contains(where: { lower.contains($0) }) &&
               !secondaryKeywords.contains(where: { lower == $0 }) {
                return attr
            }
        }
        // Fall back to first non-secondary
        for attr in attributes {
            let lower = attr.lowercased()
            if !secondaryKeywords.contains(where: { lower == $0 }) {
                return attr
            }
        }
        return attributes.first
    }

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    private func formatDuration(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - MusicBrainz API Response Types

struct MBBrowseArtistsResponse: Decodable {
    let artists: [MBArtistResult]
}

struct MBArtistResult: Decodable {
    let id: String
    let name: String
    let sortName: String?
    let disambiguation: String?
}

struct MBBrowseReleasesResponse: Decodable {
    let releases: [MBReleaseResult]
}

struct MBReleaseResult: Decodable {
    let id: String
    let title: String
    let date: String?
    let country: String?
    let artistCredit: [MBArtistCredit]?
}

struct MBArtistCredit: Decodable {
    let name: String
}

struct MBArtistDetail: Decodable {
    let id: String
    let name: String
    let sortName: String?
    let disambiguation: String?
    let type: String?
    let relations: [MBRelation]?
}

struct MBRelation: Decodable {
    let type: String?
    let url: MBUrl?
}

struct MBUrl: Decodable {
    let resource: String?
}

struct MBReleaseDetail: Decodable {
    let id: String
    let title: String
    let date: String?
    let country: String?
    let artistCredit: [MBArtistCredit]?
    let media: [MBMedium]?
}

struct MBMedium: Decodable {
    let position: Int?
    let tracks: [MBTrack]?
}

struct MBTrack: Decodable {
    let position: Int?
    let title: String?
    let recording: MBRecording?
}

struct MBRecording: Decodable {
    let title: String?
    let length: Int?
}

struct MBReleaseGroupResponse: Decodable {
    let releaseGroups: [MBReleaseGroup]
}

struct MBReleaseGroup: Decodable {
    let id: String
    let title: String
    let primaryType: String?
    let firstReleaseDate: String?
}

struct MBArtistWithRels: Decodable {
    let id: String
    let name: String
    let relations: [MBArtistRelation]?
}

struct MBArtistRelation: Decodable {
    let type: String?
    let artist: MBArtistRef?
    let attributes: [String]?
    let ended: Bool?
}

struct MBArtistRef: Decodable {
    let id: String
    let name: String
}
