import Foundation
import Observation
import SwiftData

enum CollectionGroupBy: String, CaseIterable, Identifiable {
    case none = "None"
    case artist = "Artist"
    case year = "Year"
    case genre = "Genre"
    case label = "Label"
    case format = "Format"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "list.bullet"
        case .artist: return "person"
        case .year: return "calendar"
        case .genre: return "guitars"
        case .label: return "building.2"
        case .format: return "opticaldisc"
        }
    }
}

/// ViewModel for the user's local collection
@MainActor
@Observable
final class CollectionViewModel {
    var searchText = ""
    var groupBy: CollectionGroupBy = .none

    func groupedItems(_ items: [CollectionItem]) -> [(key: String, items: [CollectionItem])] {
        switch groupBy {
        case .none:
            return []
        case .artist:
            return groupAndSort(items) { $0.artistName }
        case .year:
            return groupAndSort(items) { $0.year.map(String.init) ?? "Unknown" }
        case .genre:
            return groupAndSort(items) { $0.genres.first ?? "Unknown" }
        case .label:
            return groupAndSort(items) { $0.labels.first ?? "Unknown" }
        case .format:
            return groupAndSort(items) { $0.formats.first ?? "Unknown" }
        }
    }

    private func groupAndSort(_ items: [CollectionItem], by keyPath: (CollectionItem) -> String) -> [(key: String, items: [CollectionItem])] {
        let dict = Dictionary(grouping: items, by: keyPath)
        return dict.sorted { $0.key < $1.key }
            .map { (key: $0.key, items: $0.value) }
    }

    func addAlbumToCollection(album: Album, notes: String = "", context: ModelContext) {
        PersistenceService.addToCollection(album: album, notes: notes, context: context)
    }

    func deleteItem(_ item: CollectionItem, context: ModelContext) {
        PersistenceService.delete(item, context: context)
    }
}
