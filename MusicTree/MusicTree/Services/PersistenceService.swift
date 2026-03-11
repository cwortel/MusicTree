import Foundation
import SwiftData

/// Handles local persistence using SwiftData
final class PersistenceService {

    /// Add an album to the user's collection
    static func addToCollection(
        album: Album,
        notes: String = "",
        context: ModelContext
    ) {
        let item = CollectionItem(
            artistName: album.artistName,
            albumTitle: album.title,
            year: album.year,
            coverImageURL: album.coverImageURL,
            genres: album.genres ?? [],
            labels: album.labels ?? [],
            formats: album.formats ?? [],
            notes: notes,
            sourceID: album.id,
            source: album.sources.map(\.rawValue).joined(separator: ",")
        )
        context.insert(item)
    }

    /// Delete a collection item
    static func delete(_ item: CollectionItem, context: ModelContext) {
        context.delete(item)
    }
}
