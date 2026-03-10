import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            CollectionListView()
                .tabItem {
                    Label("Collection", systemImage: "music.note.list")
                }
        }
    }
}

#Preview {
    ContentView()
}
