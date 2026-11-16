
import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(PlaybackManager.self) private var playback
    @Query(filter: #Predicate<TrackEntity> { $0.isFavorite == true }) private var favorites: [TrackEntity]
    var body: some View {
        Group {
            if favorites.isEmpty {
                EmptyStateView(icon: "heart", title: "No favorites yet", message: "Tap the heart on any song to keep it here.")
            } else {
                List {
                    ForEach(favorites) { entity in
                        SongRow(track: entity.snapshot(), isCurrent: playback.currentTrack?.id == entity.id) {
                            playback.play(tracks: favorites.map { $0.snapshot() }, startAt: favorites.firstIndex(of: entity) ?? 0)
                        }
                        .contextMenu { TrackActionsMenu(track: entity.snapshot()) }
                        .listRowBackground(DS.secondaryBackground)
                    }
                }.scrollContentBackground(.hidden)
            }
        }
        .sonoraBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { playback.play(tracks: favorites.map { $0.snapshot() }); if !playback.queue.isShuffled { playback.toggleShuffle() } } label: {
                    Image(systemName: "shuffle")
                }.disabled(favorites.isEmpty).accessibilityLabel("Shuffle Favorites")
            }
        }
    }
}

struct RecentlyPlayedView: View {
    @Environment(PlaybackManager.self) private var playback
    @Query private var allTracks: [TrackEntity]
    @Query(sort: \ListeningHistoryEntity.playedAt, order: .reverse) private var history: [ListeningHistoryEntity]
    private var recent: [TrackEntity] {
        allTracks.filter { $0.lastPlayedAt != nil }.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
    }
    private var mostPlayed: [TrackEntity] { allTracks.filter { $0.playCount > 0 }.sorted { $0.playCount > $1.playCount } }
    var body: some View {
        List {
            if recent.isEmpty {
                Text("Nothing played yet. Your listening history will appear here.").foregroundStyle(DS.textSecondary)
                    .listRowBackground(DS.secondaryBackground)
            } else {
                Section("Recently Played") {
                    ForEach(recent) { entity in
                        SongRow(track: entity.snapshot()) { playback.play(tracks: recent.map { $0.snapshot() }, startAt: recent.firstIndex(of: entity) ?? 0) }
                            .listRowBackground(DS.secondaryBackground)
                    }
                }
                Section("Most Played") {
                    ForEach(mostPlayed.prefix(10)) { entity in
                        HStack {
                            SongRow(track: entity.snapshot()) { playback.playSingle(entity.snapshot()) }
                            Text("\(entity.playCount)×").font(.caption).foregroundStyle(DS.textSecondary)
                        }.listRowBackground(DS.secondaryBackground)
                    }
                }
                Section("Statistics") {
                    LabeledContent("Total plays recorded", value: "\(history.count)")
                    LabeledContent("Tracks played", value: "\(recent.count)")
                }.listRowBackground(DS.secondaryBackground)
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
    }
}

struct DownloadsView: View {
    @Environment(PlaybackManager.self) private var playback
    @Environment(DownloadManager.self) private var downloads
    @Environment(\.modelContext) private var context
    @Query private var allTracks: [TrackEntity]
    private var downloaded: [TrackEntity] { allTracks.filter { $0.source == .downloaded } }
    var body: some View {
        List {
            Section("Storage") {
                let usage = ArtworkCache.storageUsage()
                LabeledContent("Imported music", value: formatBytes(usage.music))
                LabeledContent("Downloads", value: formatBytes(usage.downloads))
            }.listRowBackground(DS.secondaryBackground)
            if !downloads.active.isEmpty {
                Section("In Progress") {
                    ForEach(Array(downloads.active.values)) { info in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(info.track.title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary)
                            ProgressView(value: info.progress)
                            HStack {
                                Text("\(Int(info.progress * 100))%").font(.caption).foregroundStyle(DS.textSecondary)
                                Spacer()
                                if info.isPaused { Button("Resume") { downloads.resume(info.track) } }
                                else { Button("Pause") { downloads.pause(info.track) } }
                                Button("Cancel", role: .destructive) { downloads.cancel(info.track) }
                            }.font(.caption)
                        }.listRowBackground(DS.secondaryBackground)
                    }
                }
            }
            Section("Downloaded") {
                if downloaded.isEmpty {
                    Text("No downloads yet. Demo tracks can be downloaded from their menu for offline playback.")
                        .foregroundStyle(DS.textSecondary)
                }
                ForEach(downloaded) { entity in
                    SongRow(track: entity.snapshot()) { playback.play(tracks: downloaded.map { $0.snapshot() }, startAt: downloaded.firstIndex(of: entity) ?? 0) }
                        .listRowBackground(DS.secondaryBackground)
                }
                .onDelete { idx in idx.forEach { removeDownload(downloaded[$0]) } }
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
    }
    private func removeDownload(_ entity: TrackEntity) {
        if let rel = entity.localRelativePath {
            try? FileManager.default.removeItem(at: FileManager.default.documentsDirectory.appendingPathComponent(rel))
        }
        context.delete(entity); try? context.save()
    }
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

/// Lists library tracks whose audio file has disappeared (flagged by the launch
/// availability check in LocalMusicService.verifyAvailability) and lets the user
/// remove the orphaned library entries.
struct MissingFilesView: View {
    @Environment(\.modelContext) private var context
    @Environment(PlaybackManager.self) private var playback
    @Query(filter: #Predicate<LocalAssetEntity> { $0.availabilityRaw == "missing" }) private var missingAssets: [LocalAssetEntity]
    @Query private var allTracks: [TrackEntity]
    private var missingTracks: [TrackEntity] {
        let paths = Set(missingAssets.compactMap { $0.managedRelativePath })
        return allTracks.filter { t in
            guard let rel = t.localRelativePath else { return false }
            return paths.contains(rel)
        }
    }
    var body: some View {
        List {
            if missingTracks.isEmpty {
                Text("No missing files. If a file was restored, relaunch SONORA to re-check.")
                    .foregroundStyle(DS.textSecondary)
                    .listRowBackground(DS.secondaryBackground)
            } else {
                Section {
                    ForEach(missingTracks) { entity in
                        HStack(spacing: 12) {
                            ArtworkView(data: entity.artworkData, size: 50)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entity.title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary).lineLimit(1)
                                Text(entity.artistName).font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                                Label("File missing", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption2).foregroundStyle(.orange)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) { remove(entity) }
                                .font(.caption)
                        }
                        .listRowBackground(DS.secondaryBackground)
                    }
                } footer: {
                    Text("These tracks are in your library but their audio files are gone (moved or deleted outside SONORA). Removing a track deletes its library entry and playlist references — there is no file left to delete.")
                }
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle("Missing Files")
    }
    private func remove(_ entity: TrackEntity) {
        if playback.currentTrack?.id == entity.id { playback.stop() }
        LocalMusicService.deleteTrack(entity, in: context)
        LocalMusicService.reconcileAlbums(in: context)
    }
}
