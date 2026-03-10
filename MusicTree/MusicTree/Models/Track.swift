import Foundation

/// Represents an individual track on an album
struct Track: Identifiable, Codable, Hashable {
    var id: String { "\(position)-\(title)" }
    let position: String
    let title: String
    let duration: String?
    let credits: [Credit]?
}
