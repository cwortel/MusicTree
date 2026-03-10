import Foundation

/// Represents an artist — may contain data from one or both APIs
struct Artist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let sortName: String?
    let disambiguation: String?
    let profile: String?
    let imageURL: String?
    let urls: [String]?

    /// IDs from each source (nil if not matched in that source)
    var discogsID: Int?
    var musicBrainzID: String?

    /// Which sources matched this artist
    var sources: Set<APISource>

    /// Members of the band (from MusicBrainz relations)
    struct Member: Codable, Hashable, Identifiable {
        var id: String { name }
        let name: String
        let instrument: String?
        let active: Bool
    }
}

enum APISource: String, Codable, Hashable {
    case discogs
    case musicBrainz
}

enum SearchType: String, CaseIterable {
    case artists = "Artists"
    case releases = "Releases"
}
