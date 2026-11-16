
import SwiftUI
import SwiftData

struct PlaylistsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlaylistEntity.updatedAt, order: .reverse) private var playlists: [PlaylistEntity]
    @State private var showCreate = false
    @State private var newName = ""
    var body: some View {
        Group {
            if playlists.isEmpty {
                EmptyStateView(icon: "music.note.list", title: "No playlists", message: "Create a playlist to organize your music.", actionTitle: "Create Playlist") { showCreate = true }
            } else {
                List {
                    ForEach(playlists) { p in
                        NavigationLink { PlaylistDetailView(playlist: p) } label: {
                            HStack(spacing: 12) {
                                ArtworkView(data: p.artworkData, size: 50)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(p.name).font(.headline).foregroundStyle(DS.textPrimary)
                                    Text(p.detail.isEmpty ? "Playlist" : p.detail).font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                                }
                            }
                        }.listRowBackground(DS.secondaryBackground)
                    }
                    .onDelete { idx in idx.forEach { delete(playlists[$0]) } }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sonoraBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .alert("New Playlist", isPresented: $showCreate) {
            TextField("Playlist name", text: $newName)
            Button("Create") { create() }
            Button("Cancel", role: .cancel) {}
        }
    }
    private func create() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        context.insert(PlaylistEntity(name: name))
        try? context.save(); newName = ""
    }
    private func delete(_ p: PlaylistEntity) {
        let items = (try? context.fetch(FetchDescriptor<PlaylistItemEntity>())) ?? []
        items.filter { $0.playlistID == p.id }.forEach { context.delete($0) }
        context.delete(p); try? context.save()
    }
}

struct PlaylistDetailView: View {
    var playlist: PlaylistEntity
    @Environment(\.modelContext) private var context
    @Environment(PlaybackManager.self) private var playback
    @Query(sort: \PlaylistItemEntity.position) private var allItems: [PlaylistItemEntity]
    @Query private var allTracks: [TrackEntity]
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showAddSongs = false

    private var items: [PlaylistItemEntity] { allItems.filter { $0.playlistID == playlist.id }.sorted { $0.position < $1.position } }
    private var tracks: [TrackSnapshot] { items.compactMap { item in allTracks.first { $0.id == item.trackID }?.snapshot() } }
    private var totalDuration: Double { tracks.reduce(0) { $0 + $1.duration } }
    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    ArtworkView(data: playlist.artworkData ?? tracks.first?.artworkData, size: 170, corner: 16)
                    Text(playlist.name).font(.title3.bold()).foregroundStyle(DS.textPrimary)
                    Text("\(tracks.count) songs • \(DS.timeString(totalDuration))").font(.caption).foregroundStyle(DS.textSecondary)
                    HStack(spacing: 14) {
                        Button { playback.play(tracks: tracks) } label: { Label("Play", systemImage: "play.fill") }
                            .buttonStyle(.borderedProminent).tint(DS.accent).disabled(tracks.isEmpty)
                        Button { playback.play(tracks: tracks); if !playback.queue.isShuffled { playback.toggleShuffle() } } label: { Label("Shuffle", systemImage: "shuffle") }
                            .buttonStyle(.bordered).disabled(tracks.isEmpty)
                    }
                }.frame(maxWidth: .infinity).listRowBackground(Color.clear)
            }
            ForEach(Array(zip(items, tracks)), id: \.0.id) { item, track in
                SongRow(track: track) { playback.play(tracks: tracks, startAt: tracks.firstIndex(of: track) ?? 0) }
                    .contextMenu { TrackActionsMenu(track: track) }
                    .listRowBackground(DS.secondaryBackground)
            }
            .onMove { from, to in move(from: from, to: to) }
            .onDelete { idx in idx.forEach { remove(items[$0]) } }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle(playlist.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showAddSongs = true } label: { Image(systemName: "plus") }
                Menu {
                    Button("Rename") { renameText = playlist.name; showRename = true }
                    EditButton()
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .alert("Rename Playlist", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Save") { playlist.name = renameText; playlist.updatedAt = Date(); try? context.save() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddSongs) { AddSongsView(playlist: playlist) }
    }
    private func move(from: IndexSet, to: Int) {
        var ordered = items
        ordered.move(fromOffsets: from, toOffset: to)
        for (i, item) in ordered.enumerated() { item.position = i }
        playlist.updatedAt = Date(); try? context.save()
    }
    private func remove(_ item: PlaylistItemEntity) {
        context.delete(item)
        for (i, it) in items.enumerated() where it.id != item.id { it.position = i }
        try? context.save()
    }
}

struct AddSongsView: View {
    var playlist: PlaylistEntity
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TrackEntity.title) private var tracks: [TrackEntity]
    @Query private var items: [PlaylistItemEntity]
    var body: some View {
        NavigationStack {
            List(tracks) { track in
                let already = items.contains { $0.playlistID == playlist.id && $0.trackID == track.id }
                Button {
                    if !already {
                        let pos = items.filter { $0.playlistID == playlist.id }.count
                        context.insert(PlaylistItemEntity(playlistID: playlist.id, trackID: track.id, position: pos))
                        if playlist.artworkData == nil { playlist.artworkData = track.artworkData }
                        try? context.save()
                    }
                } label: {
                    HStack {
                        SongRow(track: track.snapshot()) {}
                        if already { Image(systemName: "checkmark").foregroundStyle(DS.accent) }
                    }
                }
                .listRowBackground(DS.secondaryBackground)
            }
            .scrollContentBackground(.hidden).sonoraBackground()
            .navigationTitle("Add Songs")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
