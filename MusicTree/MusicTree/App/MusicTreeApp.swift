import SwiftUI
import SwiftData

@main
struct MusicTreeApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([CollectionItem.self])
        let config = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema changed — delete old store and retry
            let url = config.url
            let related = [url,
                           url.deletingPathExtension().appendingPathExtension("store-shm"),
                           url.deletingPathExtension().appendingPathExtension("store-wal")]
            for file in related { try? FileManager.default.removeItem(at: file) }
            container = try! ModelContainer(for: schema, configurations: [config])
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
