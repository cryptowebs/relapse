import SwiftUI

struct MainTabsView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "house.fill") }
            UrgeDiscoverView()
                .tabItem { Label("Discover", systemImage: "magnifyingglass.circle.fill") }
            MyUrgesView()
                .tabItem { Label("My Urges", systemImage: "list.bullet") }
            MiniGameView()
                .tabItem { Label("Play", systemImage: "gamecontroller.fill") }
        }
        .tint(AppTheme.accent)
    }
}
