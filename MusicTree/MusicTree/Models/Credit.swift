import Foundation

/// Represents a credit on an album or track (producer, engineer, musician, etc.)
struct Credit: Identifiable, Codable, Hashable {
    var id: String { "\(name)-\(role)" }
    let name: String
    let role: String
    let tracks: String?
}

/// Grouping of credits by category for display
enum CreditCategory: String, CaseIterable {
    case producer = "Producer"
    case engineer = "Engineer"
    case musician = "Musician"
    case vocals = "Vocals"
    case writer = "Writer"
    case mixing = "Mixing"
    case mastering = "Mastering"
    case other = "Other"
}
