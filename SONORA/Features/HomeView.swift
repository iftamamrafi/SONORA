
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(PlaybackManager.self) private var playback
    @Environment(NetworkMonitor.self) private var network
    @Query(sort: \TrackEntity.dateAdded, order: .reverse) private var allTracks: [TrackEntity]
    @Query(sort: \PlaylistEntity.updatedAt, order: .reverse) private var playlists: [PlaylistEntity]
    @State private var trending: [TrackSnapshot] = []
    @State private var showImporter = false
    @State private var isLoadingTrending = true

    private var localTracks: [TrackEntity] { allTracks.filter { $0.source != .online } }
    private var recentPlayed: [TrackEntity] {
        allTracks.filter { $0.lastPlayedAt != nil }.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
    }
    private var favorites: [TrackEntity] { allTracks.filter { $0.isFavorite } }
    private var downloads: [TrackEntity] { allTracks.filter { $0.source == .downloaded } }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h { case 5..<12: return "Good morning"; case 12..<17: return "Good afternoon"; case 17..<22: return "Good evening"; default: return "Good night" }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                if allTracks.isEmpty && trending.isEmpty && !isLoadingTrending {
                    EmptyStateView(icon: "music.note.list", title: "Your library is empty",
                                   message: "Import music from the Files app to start listening offline, or explore the clearly-labeled demo tracks.",
                                   actionTitle: "Import Music") { showImporter = true }
                }
                if !recentPlayed.isEmpty { trackSection("Recently Played", tracks: recentPlayed) }
                trendingSection
                if !localTracks.isEmpty { trackSection("Recently Added", tracks: Array(localTracks.prefix(10))) }
                if !favorites.isEmpty { trackSection("Your Favorites", tracks: favorites) }
                if !downloads.isEmpty { trackSection("Downloaded", tracks: downloads) }
                if !playlists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Your Playlists")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(playlists) { p in
                                    NavigationLink { PlaylistDetailView(playlist: p) } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ArtworkView(data: p.artworkData, size: 140, corner: 14)
                                            Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary).lineLimit(1)
                                        }.frame(width: 140)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                if !network.isOnline {
                    Label("You are offline — showing your local library.", systemImage: "wifi.slash")
                        .font(.caption).foregroundStyle(DS.textSecondary)
                }
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 24)
        }
        .sonoraBackground()
        .navigationTitle("SONORA")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showImporter = true } label: { Image(systemName: "square.and.arrow.down") }
                    .accessibilityLabel("Import Music")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
            }
        }
        .musicImporter(isPresented: $showImporter)
        .task { await loadTrending() }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SONORA").font(.system(size: 15, weight: .black)).tracking(4).foregroundStyle(DS.accent)
            Text(greeting).font(.largeTitle.bold()).foregroundStyle(DS.textPrimary)
            Text("Your Music. Your World. Always in Rhythm.").font(.subheadline).foregroundStyle(DS.textSecondary)
        }
    }
    private func trackSection(_ title: String, tracks: [TrackEntity]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(tracks) { entity in
                        TrackCard(track: entity.snapshot()) {
                            playback.play(tracks: tracks.map { $0.snapshot() }, startAt: tracks.firstIndex(of: entity) ?? 0)
                        }
                    }
                }
            }
        }
    }
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Trending — Demo")
            if !appState.provider.isConfigured {
                Text("Online provider is not configured. Enable the demo provider in Settings to browse test tracks.")
                    .font(.subheadline).foregroundStyle(DS.textSecondary)
            } else if !network.isOnline {
                Text("Offline — trending demo tracks are unavailable.").font(.subheadline).foregroundStyle(DS.textSecondary)
            } else if isLoadingTrending {
                HStack(spacing: 14) { ForEach(0..<3, id: \.self) { _ in RoundedRectangle(cornerRadius: 14).fill(DS.surface).frame(width: 150, height: 190) } }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(trending) { t in TrackCard(track: t) { playback.play(tracks: trending, startAt: trending.firstIndex(of: t) ?? 0) } }
                    }
                }
                Text("Demo content: SoundHelix test audio, labeled DEMO. Not a commercial catalogue.")
                    .font(.caption2).foregroundStyle(DS.textSecondary)
            }
        }
    }
    private func loadTrending() async {
        isLoadingTrending = true
        trending = (try? await appState.provider.trending()) ?? []
        isLoadingTrending = false
    }
}
