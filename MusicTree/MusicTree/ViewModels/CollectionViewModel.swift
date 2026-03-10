import Foundation
import Observation
import SwiftData

/// ViewModel for the user's local collection
@MainActor
@Observable
final class CollectionViewModel {
    var searchText = ""

    func addAlbumToCollection(album: Album, notes: String = "", context: ModelContext) {
        PersistenceService.addToCollection(album: album, notes: notes, context: context)
    }

    func deleteItem(_ item: CollectionItem, context: ModelContext) {
        PersistenceService.delete(item, context: context)
    }
}
