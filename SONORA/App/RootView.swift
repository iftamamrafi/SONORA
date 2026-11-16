
import SwiftUI

struct RootView: View {
    @Environment(PlaybackManager.self) private var playback
    @State private var selectedTab = 0
    @State private var showNowPlaying = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            NavigationStack { ExploreView() }
                .tabItem { Label("Explore", systemImage: "compass.drawing") }.tag(1)
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "music.note.list") }.tag(2)
            NavigationStack { SearchView() }
                .tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(3)
        }
        .tint(DS.accent)
        .safeAreaInset(edge: .bottom) {
            if playback.currentTrack != nil {
                MiniPlayerView { showNowPlaying = true }
            }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
    }
}
