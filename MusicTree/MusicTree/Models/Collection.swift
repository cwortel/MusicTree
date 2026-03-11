import Foundation
import SwiftData

/// A user's collection item — stored locally via SwiftData
@Model
final class CollectionItem {
    var artistName: String
    var albumTitle: String
    var year: Int?
    var coverImageURL: String?
    var genres: [String]
    var labels: [String]
    var formats: [String]
    var notes: String
    var dateAdded: Date
    var sourceID: String?
    var source: String?

    init(
        artistName: String,
        albumTitle: String,
        year: Int? = nil,
        coverImageURL: String? = nil,
        genres: [String] = [],
        labels: [String] = [],
        formats: [String] = [],
        notes: String = "",
        dateAdded: Date = .now,
        sourceID: String? = nil,
        source: String? = nil
    ) {
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.year = year
        self.coverImageURL = coverImageURL
        self.genres = genres
        self.labels = labels
        self.formats = formats
        self.notes = notes
        self.dateAdded = dateAdded
        self.sourceID = sourceID
        self.source = source
    }
}
