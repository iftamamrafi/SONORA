
import SwiftUI
import SwiftData

enum SongSort: String, CaseIterable { case title = "Title", artist = "Artist", album = "Album", duration = "Duration", recent = "Recently Added" }

struct SongsListView: View {
    @Environment(PlaybackManager.self) private var playback
    @Query(sort: \TrackEntity.title) private var tracks: [TrackEntity]
    @State private var sort: SongSort = .title
    @State private var filter: TrackSource? = nil
    @State private var editingTrack: TrackEntity? = nil
    private var displayed: [TrackEntity] {
        var list = tracks.filter { $0.source != .online || $0.localRelativePath != nil }
        if let filter { list = list.filter { $0.source == filter } }
        switch sort {
        case .title: return list.sorted { $0.title < $1.title }
        case .artist: return list.sorted { $0.artistName < $1.artistName }
        case .album: return list.sorted { $0.albumTitle < $1.albumTitle }
        case .duration: return list.sorted { $0.duration < $1.duration }
        case .recent: return list.sorted { $0.dateAdded > $1.dateAdded }
        }
    }
    var body: some View {
        Group {
            if displayed.isEmpty {
                EmptyStateView(icon: "music.note", title: "No songs yet", message: "Import music from the Files app using the import button.")
            } else {
                List {
                    ForEach(displayed) { entity in
                        let snap = entity.snapshot()
                        SongRow(track: snap, isCurrent: playback.currentTrack?.id == snap.id) {
                            playback.play(tracks: displayed.map { $0.snapshot() }, startAt: displayed.firstIndex(of: entity) ?? 0)
                        }
                        .contextMenu { TrackActionsMenu(track: snap, onEditMetadata: { editingTrack = entity }) }
                        .listRowBackground(DS.secondaryBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $editingTrack) { entity in EditTrackMetadataView(track: entity) }
        .sonoraBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sort) { ForEach(SongSort.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    Menu("Filter Source") {
                        Button("All Sources") { filter = nil }
                        Button("Local") { filter = .local }
                        Button("Downloaded") { filter = .downloaded }
                    }
                } label: { Image(systemName: "arrow.up.arrow.down") }
            }
        }
    }
}

struct AlbumsListView: View {
    @Query(sort: \AlbumEntity.title) private var albums: [AlbumEntity]
    var body: some View {
        Group {
            if albums.isEmpty {
                EmptyStateView(icon: "square.stack", title: "No albums", message: "Albums appear here after you import music with album metadata.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                        ForEach(albums) { album in
                            NavigationLink { AlbumDetailView(album: album) } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ArtworkView(data: album.artworkData, size: 160, corner: 14)
                                    Text(album.title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary).lineLimit(1)
                                    Text("\(album.artistName) • \(album.trackCount) tracks").font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding(18)
                }
            }
        }
        .sonoraBackground()
    }
}

struct AlbumDetailView: View {
    var album: AlbumEntity
    @Environment(PlaybackManager.self) private var playback
    @Query private var allTracks: [TrackEntity]
    private var tracks: [TrackEntity] {
        allTracks.filter { $0.albumTitle == album.title && $0.artistName == album.artistName }
            .sorted { ($0.trackNumber ?? 0) < ($1.trackNumber ?? 0) }
    }
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ArtworkView(data: album.artworkData, size: 200, corner: 16)
                    Text(album.title).font(.title3.bold()).foregroundStyle(DS.textPrimary)
                    Text(album.artistName).foregroundStyle(DS.textSecondary)
                    if let y = album.releaseYear { Text(String(y)).font(.caption).foregroundStyle(DS.textSecondary) }
                    HStack(spacing: 14) {
                        Button { playAll(shuffle: false) } label: { Label("Play", systemImage: "play.fill") }
                            .buttonStyle(.borderedProminent).tint(DS.accent)
                        Button { playAll(shuffle: true) } label: { Label("Shuffle", systemImage: "shuffle") }
                            .buttonStyle(.bordered)
                    }
                }.frame(maxWidth: .infinity).listRowBackground(Color.clear)
            }
            ForEach(tracks) { entity in
                SongRow(track: entity.snapshot()) {
                    playback.play(tracks: tracks.map { $0.snapshot() }, startAt: tracks.firstIndex(of: entity) ?? 0)
                }
                .contextMenu { TrackActionsMenu(track: entity.snapshot()) }
                .listRowBackground(DS.secondaryBackground)
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle(album.title)
    }
    private func playAll(shuffle: Bool) {
        playback.play(tracks: tracks.map { $0.snapshot() })
        if shuffle && !playback.queue.isShuffled { playback.toggleShuffle() }
    }
}

struct ArtistsListView: View {
    @Query private var tracks: [TrackEntity]
    private var artists: [(name: String, count: Int, artwork: Data?)] {
        var dict: [String: (Int, Data?)] = [:]
        for t in tracks { var e = dict[t.artistName] ?? (0, t.artworkData); e.0 += 1; if e.1 == nil { e.1 = t.artworkData }; dict[t.artistName] = e }
        return dict.map { (name: $0.key, count: $0.value.0, artwork: $0.value.1) }.sorted { $0.name < $1.name }
    }
    var body: some View {
        Group {
            if artists.isEmpty {
                EmptyStateView(icon: "person.2", title: "No artists", message: "Artists appear here after you import music.")
            } else {
                List(artists, id: \.name) { artist in
                    NavigationLink { ArtistDetailView(artistName: artist.name) } label: {
                        HStack(spacing: 12) {
                            ArtworkView(data: artist.artwork, size: 48, corner: 24)
                            VStack(alignment: .leading) {
                                Text(artist.name).font(.headline).foregroundStyle(DS.textPrimary)
                                Text("\(artist.count) tracks").font(.caption).foregroundStyle(DS.textSecondary)
                            }
                        }
                    }.listRowBackground(DS.secondaryBackground)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sonoraBackground()
    }
}

struct ArtistDetailView: View {
    var artistName: String
    @Environment(PlaybackManager.self) private var playback
    @Query private var allTracks: [TrackEntity]
    private var tracks: [TrackEntity] { allTracks.filter { $0.artistName == artistName }.sorted { $0.albumTitle < $1.albumTitle } }
    private var albums: [String] { Array(Set(tracks.map { $0.albumTitle })).sorted() }
    var body: some View {
        List {
            Section("Albums") {
                ForEach(albums, id: \.self) { name in
                    HStack { Image(systemName: "square.stack"); Text(name).foregroundStyle(DS.textPrimary) }
                        .listRowBackground(DS.secondaryBackground)
                }
            }
            Section("Tracks") {
                ForEach(tracks) { entity in
                    SongRow(track: entity.snapshot()) {
                        playback.play(tracks: tracks.map { $0.snapshot() }, startAt: tracks.firstIndex(of: entity) ?? 0)
                    }
                    .contextMenu { TrackActionsMenu(track: entity.snapshot()) }
                    .listRowBackground(DS.secondaryBackground)
                }
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle(artistName)
    }
}
