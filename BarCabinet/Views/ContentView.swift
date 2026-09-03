import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "sparkles") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            MyBarView()
                .tabItem { Label("My Bar", systemImage: "cabinet") }
        }
    }
}

#Preview {
    ContentView()
}
