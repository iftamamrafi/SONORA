
import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(AppState.self) private var appState
    @Environment(PlaybackManager.self) private var playback
    @Environment(NetworkMonitor.self) private var network
    @Environment(PreferencesStore.self) private var preferences
    @Query private var allTracks: [TrackEntity]
    @State private var query = ""
    @State private var onlineResults: [TrackSnapshot] = []
    @State private var isSearchingOnline = false
    @State private var searchTask: Task<Void, Never>?

    private var localResults: [TrackSnapshot] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return allTracks.filter {
            $0.title.lowercased().contains(q) || $0.artistName.lowercased().contains(q) || $0.albumTitle.lowercased().contains(q)
        }.map { $0.snapshot() }
    }
    var body: some View {
        List {
            if query.isEmpty {
                if !preferences.searchHistory.isEmpty {
                    Section {
                        ForEach(preferences.searchHistory, id: \.self) { term in
                            Button { query = term } label: {
                                HStack { Image(systemName: "clock.arrow.circlepath"); Text(term).foregroundStyle(DS.textPrimary) }
                            }.listRowBackground(DS.secondaryBackground)
                        }
                    } header: {
                        HStack { Text("Recent Searches"); Spacer()
                            Button("Clear") { preferences.clearSearchHistory() }.font(.caption) }
                    }
                }
                Section("Browse") {
                    ForEach(GenreItem.all) { g in
                        NavigationLink { GenreDetailView(genre: g) } label: { Label(g.name, systemImage: g.icon) }
                            .listRowBackground(DS.secondaryBackground)
                    }
                }
            } else {
                if !localResults.isEmpty {
                    Section("In Your Library") {
                        ForEach(localResults) { t in
                            SongRow(track: t) { playback.play(tracks: localResults, startAt: localResults.firstIndex(of: t) ?? 0); preferences.addSearchTerm(query) }
                                .contextMenu { TrackActionsMenu(track: t) }
                                .listRowBackground(DS.secondaryBackground)
                        }
                    }
                }
                Section("Online — Demo Provider") {
                    if !appState.provider.isConfigured {
                        Text("Provider not configured.").foregroundStyle(DS.textSecondary).listRowBackground(DS.secondaryBackground)
                    } else if !network.isOnline {
                        Text("Offline — online search unavailable.").foregroundStyle(DS.textSecondary).listRowBackground(DS.secondaryBackground)
                    } else if isSearchingOnline {
                        HStack { ProgressView(); Text("Searching…").foregroundStyle(DS.textSecondary) }.listRowBackground(DS.secondaryBackground)
                    } else if onlineResults.isEmpty {
                        Text("No online results.").foregroundStyle(DS.textSecondary).listRowBackground(DS.secondaryBackground)
                    } else {
                        ForEach(onlineResults) { t in
                            SongRow(track: t) { playback.play(tracks: onlineResults, startAt: onlineResults.firstIndex(of: t) ?? 0); preferences.addSearchTerm(query) }
                                .contextMenu { TrackActionsMenu(track: t) }
                                .listRowBackground(DS.secondaryBackground)
                        }
                    }
                }
                if localResults.isEmpty && onlineResults.isEmpty && !isSearchingOnline {
                    Text("No results for \u{201C}\(query)\u{201D}.").foregroundStyle(DS.textSecondary).listRowBackground(DS.secondaryBackground)
                }
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Songs, artists, albums")
        .onChange(of: query) { _, newValue in scheduleOnlineSearch(newValue) }
    }
    private func scheduleOnlineSearch(_ value: String) {
        searchTask?.cancel()
        let q = value.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty, appState.provider.isConfigured, network.isOnline else { onlineResults = []; return }
        isSearchingOnline = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            if Task.isCancelled { return }
            let results = (try? await appState.provider.search(query: q)) ?? []
            if !Task.isCancelled { onlineResults = results; isSearchingOnline = false }
        }
    }
}
