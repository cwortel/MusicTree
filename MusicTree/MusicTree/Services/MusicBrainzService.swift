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
            URLQueryItem(name: "type", value: "album|ep|single"),
            URLQueryItem(name: "inc", value: "genres")
        ]) else { return [] }

        let response: MBReleaseGroupResponse = try await client.get(url, headers: headers)
        return response.releaseGroups.map { rg in
            let genres = rg.genres?.compactMap { $0.name }.filter { !$0.isEmpty }
            return Album(
                id: "mb-\(rg.id)",
                title: rg.title,
                artistName: "",
                year: rg.firstReleaseDate.flatMap { Int($0.prefix(4)) },
                genres: genres?.isEmpty == false ? genres : nil,
                styles: nil,
                coverImageURL: "https://coverartarchive.org/release-group/\(rg.id)/front-250",
                tracklist: nil,
                credits: nil,
                formats: rg.primaryType.map { [$0] },
                country: nil,
                labels: nil,
                discogsID: nil,
                musicBrainzID: rg.id,
                sources: [.musicBrainz],
                isReleaseGroup: true
            )
        }
    }

    func getArtistMembers(mbid: String) async throws -> [Artist.Member] {
        guard let url = buildURL(path: "/artist/\(mbid)", queryItems: [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "inc", value: "artist-rels")
        ]) else { return [] }

        let response: MBArtistWithRels = try await client.get(url, headers: headers)

        // Collect all relations per member, then aggregate instruments
        var memberData: [String: (mbid: String?, attributes: [String], active: Bool)] = [:]
        for rel in response.relations ?? [] {
            guard rel.type == "member of band",
                  let targetName = rel.artist?.name else { continue }
            let attrs = rel.attributes ?? []
            let active = !(rel.ended ?? false)
            let mbid = rel.artist?.id
            if var existing = memberData[targetName] {
                existing.attributes.append(contentsOf: attrs)
                if active { existing.active = true }
                if existing.mbid == nil { existing.mbid = mbid }
                memberData[targetName] = existing
            } else {
                memberData[targetName] = (mbid: mbid, attributes: attrs, active: active)
            }
        }

        return memberData.map { name, data in
            let cleaned = Self.cleanInstruments(from: data.attributes)
            return Artist.Member(name: name, musicBrainzID: data.mbid, instruments: cleaned, active: data.active)
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

        // Parse release-level artist relations into credits (musicians, producers, etc.)
        var credits: [Credit] = []
        for rel in response.relations ?? [] {
            guard let name = rel.artist?.name, let type = rel.type else { continue }
            let role: String
            let attributes = rel.attributes ?? []
            switch type {
            case "performer", "instrument", "vocal":
                role = attributes.isEmpty ? type.capitalized : attributes.map(\.capitalized).joined(separator: ", ")
            case "producer":
                role = "Producer"
            case "engineer":
                role = "Engineer"
            case "mix":
                role = "Mixing"
            case "recording":
                role = "Recording"
            case "mastering":
                role = "Mastering"
            default:
                role = type.capitalized
            }
            credits.append(Credit(name: name, role: role, tracks: nil))
        }

        // Also collect recording-level relations (per-track performers)
        for medium in response.media ?? [] {
            for track in medium.tracks ?? [] {
                for rel in track.recording?.relations ?? [] {
                    guard let name = rel.artist?.name, let type = rel.type else { continue }
                    let attributes = rel.attributes ?? []
                    let role: String
                    switch type {
                    case "performer", "instrument", "vocal":
                        role = attributes.isEmpty ? type.capitalized : attributes.map(\.capitalized).joined(separator: ", ")
                    default:
                        role = type.capitalized
                    }
                    credits.append(Credit(name: name, role: role, tracks: track.title ?? track.recording?.title))
                }
            }
        }

        // Deduplicate credits with same name + role (merge track references)
        var deduped: [String: Credit] = [:]
        for credit in credits {
            let key = "\(credit.name)|\(credit.role)"
            if let existing = deduped[key] {
                let mergedTracks = [existing.tracks, credit.tracks].compactMap { $0 }.joined(separator: ", ")
                deduped[key] = Credit(name: credit.name, role: credit.role, tracks: mergedTracks.isEmpty ? nil : mergedTracks)
            } else {
                deduped[key] = credit
            }
        }

        return Album(
            id: "mb-\(response.id)",
            title: response.title,
            artistName: response.artistCredit?.map(\.name).joined(separator: ", ") ?? "",
            year: response.date.flatMap { Int($0.prefix(4)) },
            genres: nil,
            styles: nil,
            coverImageURL: "https://coverartarchive.org/release/\(response.id)/front-500",
            tracklist: tracks,
            credits: deduped.isEmpty ? nil : Array(deduped.values).sorted { $0.role < $1.role },
            formats: nil,
            country: response.country,
            labels: nil,
            discogsID: nil,
            musicBrainzID: response.id,
            sources: [.musicBrainz]
        )
    }

    // MARK: - Helpers

    /// Clean and deduplicate instrument attributes, returning them sorted with core instruments first.
    private static func cleanInstruments(from attributes: [String]) -> [String] {
        guard !attributes.isEmpty else { return [] }
        // Deduplicate case-insensitively, keep original casing
        var seen = Set<String>()
        var unique: [String] = []
        for attr in attributes {
            let lower = attr.lowercased()
            if !seen.contains(lower) {
                seen.insert(lower)
                unique.append(attr)
            }
        }
        let coreKeywords = ["vocals", "guitar", "bass guitar", "drums",
                            "keyboard", "keyboards", "piano", "synthesizer",
                            "lead vocals", "bass", "lead guitar", "rhythm guitar"]
        // Sort: core instruments first
        return unique.sorted { a, b in
            let aCore = coreKeywords.contains(where: { a.lowercased().contains($0) })
            let bCore = coreKeywords.contains(where: { b.lowercased().contains($0) })
            if aCore != bCore { return aCore }
            return a < b
        }
    }

    /// Fetch the first official release ID from a release-group, then load full release detail.
    func getReleaseGroupDetail(rgid: String) async throws -> Album {
        guard let url = buildURL(path: "/release-group/\(rgid)", queryItems: [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "inc", value: "releases")
        ]) else {
            throw NetworkError.invalidResponse
        }

        let response: MBReleaseGroupDetail = try await client.get(url, headers: headers)
        // Prefer an "Official" release, fall back to first available
        let releaseID = response.releases?
            .first(where: { $0.status == "Official" })?.id
            ?? response.releases?.first?.id

        guard let rid = releaseID else {
            throw NetworkError.invalidResponse
        }
        return try await getRelease(mbid: rid)
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

    enum CodingKeys: String, CodingKey {
        case id, name, disambiguation
        case sortName = "sort-name"
    }
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

    enum CodingKeys: String, CodingKey {
        case id, title, date, country
        case artistCredit = "artist-credit"
    }
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

    enum CodingKeys: String, CodingKey {
        case id, name, disambiguation, type, relations
        case sortName = "sort-name"
    }
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
    let relations: [MBReleaseArtistRelation]?

    enum CodingKeys: String, CodingKey {
        case id, title, date, country, media, relations
        case artistCredit = "artist-credit"
    }
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
    let relations: [MBReleaseArtistRelation]?
}

struct MBReleaseArtistRelation: Decodable {
    let type: String?
    let artist: MBArtistRef?
    let attributes: [String]?
}

struct MBReleaseGroupResponse: Decodable {
    let releaseGroups: [MBReleaseGroup]

    enum CodingKeys: String, CodingKey {
        case releaseGroups = "release-groups"
    }
}

struct MBReleaseGroup: Decodable {
    let id: String
    let title: String
    let primaryType: String?
    let firstReleaseDate: String?
    let genres: [MBGenreTag]?

    enum CodingKeys: String, CodingKey {
        case id, title, genres
        case primaryType = "primary-type"
        case firstReleaseDate = "first-release-date"
    }
}

struct MBGenreTag: Decodable {
    let name: String
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

struct MBReleaseGroupDetail: Decodable {
    let id: String
    let title: String
    let releases: [MBReleaseGroupRelease]?
}

struct MBReleaseGroupRelease: Decodable {
    let id: String
    let status: String?
}
