import SwiftUI

struct MainTabView: View {
    @State private var tab: RootTab = .home

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectedTab: $tab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(RootTab.home)

            GameHubView(game: .starCollector)
                .tabItem {
                    Label(GameType.starCollector.displayTitle, systemImage: GameType.starCollector.tabSystemImage)
                }
                .tag(RootTab.game(.starCollector))

            GameHubView(game: .colorMatch)
                .tabItem {
                    Label(GameType.colorMatch.displayTitle, systemImage: GameType.colorMatch.tabSystemImage)
                }
                .tag(RootTab.game(.colorMatch))

            GameHubView(game: .shapeEscape)
                .tabItem {
                    Label(GameType.shapeEscape.displayTitle, systemImage: GameType.shapeEscape.tabSystemImage)
                }
                .tag(RootTab.game(.shapeEscape))
        }
        .tint(Color.appPrimary)
    }
}
