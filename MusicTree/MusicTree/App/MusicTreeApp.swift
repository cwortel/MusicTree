import SwiftUI
import SwiftData

@main
struct MusicTreeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [CollectionItem.self])
    }
}
