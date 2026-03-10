import Foundation

/// Client for the Discogs API
/// Docs: https://www.discogs.com/developers
final class DiscogsService {
    private let client = NetworkClient.shared
    private let baseURL = "https://api.discogs.com"

    // TODO: Add your Discogs personal access token here
    private let token = "SZIHIWdDmGjtSPKnlWLEIEotznzvPKeMXKFYZIho"

    private var authHeaders: [String: String] {
        var headers = ["User-Agent": "MusicTree/1.0"]
        if !token.isEmpty {
            headers["Authorization"] = "Discogs token=\(token)"
        }
        return headers
    }

    // MARK: - Search

    func searchArtists(query: String) async throws -> [Artist] {
        guard let url = buildURL(path: "/database/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artist")
        ]) else { return [] }

        let response: DiscogsSearchResponse = try await client.get(url, headers: authHeaders)
        return response.results.map { result in
            Artist(
                id: "discogs-\(result.id)",
                name: result.title,
                sortName: nil,
                disambiguation: nil,
                profile: nil,
                imageURL: result.coverImage,
                urls: result.uri.map { ["\(baseURL)\($0)"] },
                discogsID: result.id,
                musicBrainzID: nil,
                sources: [.discogs]
            )
        }
    }

    func searchReleases(query: String) async throws -> [Album] {
        guard let url = buildURL(path: "/database/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "release")
        ]) else { return [] }

        let response: DiscogsSearchResponse = try await client.get(url, headers: authHeaders)
        return response.results.map { result in
            Album(
                id: "discogs-\(result.id)",
                title: result.title,
                artistName: "",
                year: result.year.flatMap { Int($0) },
                genres: result.genre,
                styles: result.style,
                coverImageURL: result.coverImage,
                tracklist: nil,
                credits: nil,
                formats: result.format,
                country: result.country,
                labels: result.label,
                discogsID: result.id,
                musicBrainzID: nil,
                sources: [.discogs]
            )
        }
    }

    // MARK: - Detail

    func getArtist(id: Int) async throws -> Artist {
        guard let url = buildURL(path: "/artists/\(id)") else {
            throw NetworkError.invalidResponse
        }

        let response: DiscogsArtistDetail = try await client.get(url, headers: authHeaders)
        return Artist(
            id: "discogs-\(response.id)",
            name: response.name,
            sortName: response.namevariations?.first,
            disambiguation: nil,
            profile: response.profile,
            imageURL: response.images?.first?.resourceUrl,
            urls: response.urls,
            discogsID: response.id,
            musicBrainzID: nil,
            sources: [.discogs]
        )
    }

    func getArtistReleases(id: Int) async throws -> [Album] {
        guard let url = buildURL(path: "/artists/\(id)/releases", queryItems: [
            URLQueryItem(name: "sort", value: "year"),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "per_page", value: "50")
        ]) else { return [] }

        let response: DiscogsArtistReleasesResponse = try await client.get(url, headers: authHeaders)
        return response.releases.map { release in
            Album(
                id: "discogs-\(release.id)",
                title: release.title,
                artistName: release.artist ?? "",
                year: release.year,
                genres: nil,
                styles: nil,
                coverImageURL: release.thumb,
                tracklist: nil,
                credits: nil,
                formats: release.format.map { [$0] },
                country: nil,
                labels: nil,
                discogsID: release.id,
                musicBrainzID: nil,
                sources: [.discogs]
            )
        }
    }

    func getRelease(id: Int) async throws -> Album {
        guard let url = buildURL(path: "/releases/\(id)") else {
            throw NetworkError.invalidResponse
        }

        let response: DiscogsReleaseDetail = try await client.get(url, headers: authHeaders)
        return Album(
            id: "discogs-\(response.id)",
            title: response.title,
            artistName: response.artists?.map(\.name).joined(separator: ", ") ?? "",
            year: response.year,
            genres: response.genres,
            styles: response.styles,
            coverImageURL: response.images?.first?.resourceUrl,
            tracklist: response.tracklist?.map { track in
                Track(
                    position: track.position,
                    title: track.title,
                    duration: track.duration,
                    credits: track.extraartists?.map { Credit(name: $0.name, role: $0.role, tracks: nil) }
                )
            },
            credits: response.extraartists?.map { Credit(name: $0.name, role: $0.role, tracks: $0.tracks) },
            formats: response.formats?.map(\.name),
            country: response.country,
            labels: response.labels?.map(\.name),
            discogsID: response.id,
            musicBrainzID: nil,
            sources: [.discogs]
        )
    }

    // MARK: - Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + path)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }
}

// MARK: - Discogs API Response Types

struct DiscogsSearchResponse: Decodable {
    let results: [DiscogsSearchResult]
}

struct DiscogsSearchResult: Decodable {
    let id: Int
    let title: String
    let coverImage: String?
    let year: String?
    let genre: [String]?
    let style: [String]?
    let format: [String]?
    let country: String?
    let label: [String]?
    let uri: String?
}

struct DiscogsArtistDetail: Decodable {
    let id: Int
    let name: String
    let profile: String?
    let namevariations: [String]?
    let urls: [String]?
    let images: [DiscogsImage]?
}

struct DiscogsReleaseDetail: Decodable {
    let id: Int
    let title: String
    let year: Int?
    let genres: [String]?
    let styles: [String]?
    let country: String?
    let artists: [DiscogsArtistRef]?
    let extraartists: [DiscogsCredit]?
    let tracklist: [DiscogsTrack]?
    let labels: [DiscogsLabel]?
    let formats: [DiscogsFormat]?
    let images: [DiscogsImage]?
}

struct DiscogsArtistRef: Decodable {
    let name: String
}

struct DiscogsCredit: Decodable {
    let name: String
    let role: String
    let tracks: String?
}

struct DiscogsTrack: Decodable {
    let position: String
    let title: String
    let duration: String?
    let extraartists: [DiscogsCredit]?
}

struct DiscogsLabel: Decodable {
    let name: String
}

struct DiscogsFormat: Decodable {
    let name: String
}

struct DiscogsImage: Decodable {
    let resourceUrl: String?
}

struct DiscogsArtistReleasesResponse: Decodable {
    let releases: [DiscogsArtistRelease]
}

struct DiscogsArtistRelease: Decodable {
    let id: Int
    let title: String
    let year: Int?
    let artist: String?
    let thumb: String?
    let format: String?
    let role: String?
}
