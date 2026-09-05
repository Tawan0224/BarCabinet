import SwiftUI

struct ContentView: View {
    @AppStorage("appearance") private var appearanceRaw: String = AppearanceMode.system.rawValue
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            mainTabs
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(AppearanceMode(rawValue: appearanceRaw)?.colorScheme)
        .task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                isShowingSplash = false
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "sparkles") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            MyBarView()
                .tabItem { Label("My Bar", systemImage: "cabinet") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
}
