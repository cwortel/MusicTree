import Foundation

/// Represents an album/release — may contain data from one or both APIs
struct Album: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let artistName: String
    let year: Int?
    let genres: [String]?
    let styles: [String]?
    let coverImageURL: String?
    let tracklist: [Track]?
    let credits: [Credit]?
    let formats: [String]?
    let country: String?
    let labels: [String]?

    var discogsID: Int?
    var musicBrainzID: String?
    var sources: Set<APISource>
    var isReleaseGroup: Bool = false

    /// Derived release type from formats (which stores primaryType for MB release-groups)
    var releaseType: String {
        if let type = formats?.first(where: { ["Album", "EP", "Single"].contains($0) }) {
            return type
        }
        return "Other"
    }
}
