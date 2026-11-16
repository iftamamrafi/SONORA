
import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState
    @Environment(PlaybackManager.self) private var playback
    @Environment(NetworkMonitor.self) private var network
    @State private var trending: [TrackSnapshot] = []
    @State private var newReleases: [TrackSnapshot] = []
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                if !appState.provider.isConfigured {
                    EmptyStateView(icon: "antenna.radiowaves.left.and.right.slash", title: "No provider configured",
                                   message: "Online discovery needs an authorized provider. SONORA ships with a clearly-labeled demo provider (SoundHelix test audio). Enable it in Settings → Provider.")
                } else if !network.isOnline {
                    EmptyStateView(icon: "wifi.slash", title: "You are offline",
                                   message: "Explore needs a connection. Your local library, playlists and downloads still work.")
                } else {
                    demoBanner
                    genreGrid
                    listSection("Trending Now", tracks: trending)
                    listSection("New Releases", tracks: newReleases)
                    if let loadError {
                        Text(loadError).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 24)
        }
        .sonoraBackground()
        .navigationTitle("Explore")
        .task { await load() }
        .refreshable { await load() }
    }
    private var demoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "flask.fill").foregroundStyle(DS.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("DEMO provider").font(.subheadline.bold()).foregroundStyle(DS.textPrimary)
                Text("SoundHelix test audio only — not a commercial catalogue.").font(.caption).foregroundStyle(DS.textSecondary)
            }
            Spacer()
        }
        .padding(14).cardStyle()
    }
    private var genreGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Genres")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GenreItem.all) { genre in
                    NavigationLink { GenreDetailView(genre: genre) } label: {
                        HStack {
                            Image(systemName: genre.icon)
                            Text(genre.name).font(.headline)
                            Spacer()
                        }
                        .foregroundStyle(DS.textPrimary)
                        .padding(16).cardStyle()
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    private func listSection(_ title: String, tracks: [TrackSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
            ForEach(tracks) { t in
                SongRow(track: t, isCurrent: playback.currentTrack?.id == t.id) {
                    playback.play(tracks: tracks, startAt: tracks.firstIndex(of: t) ?? 0)
                }
                .contextMenu { TrackActionsMenu(track: t) }
            }
        }
    }
    private func load() async {
        guard appState.provider.isConfigured, network.isOnline else { return }
        do {
            trending = try await appState.provider.trending()
            newReleases = try await appState.provider.newReleases()
            loadError = nil
        } catch { loadError = error.localizedDescription }
    }
}

struct GenreDetailView: View {
    var genre: GenreItem
    @Environment(AppState.self) private var appState
    @Environment(PlaybackManager.self) private var playback
    @State private var tracks: [TrackSnapshot] = []
    var body: some View {
        List {
            ForEach(tracks) { t in
                SongRow(track: t) { playback.play(tracks: tracks, startAt: tracks.firstIndex(of: t) ?? 0) }
                    .listRowBackground(DS.secondaryBackground)
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle(genre.name)
        .task { tracks = (try? await appState.provider.search(query: genre.name)) ?? [] }
    }
}
