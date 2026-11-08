import SwiftUI

/// Primary navigation: Home, Explore, Learn and Settings.
struct ContentView: View {
    enum Tab: Hashable {
        case home, explore, learn, settings
    }

    @State private var selection: Tab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            ExploreView()
                .tabItem { Label("Explore", systemImage: "arkit") }
                .tag(Tab.explore)

            LearnView()
                .tabItem { Label("Learn", systemImage: "book.fill") }
                .tag(Tab.learn)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        .screenBackground()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
