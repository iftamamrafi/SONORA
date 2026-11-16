
import SwiftUI
import SwiftData

enum LibrarySegment: String, CaseIterable { case songs = "Songs", albums = "Albums", artists = "Artists", playlists = "Playlists", favorites = "Favorites", recent = "Recent", downloads = "Downloads" }

struct LibraryView: View {
    @Query(filter: #Predicate<LocalAssetEntity> { $0.availabilityRaw == "missing" }) private var missingAssets: [LocalAssetEntity]
    @State private var segment: LibrarySegment = .songs
    @State private var showImporter = false
    var body: some View {
        VStack(spacing: 0) {
            Picker("Library", selection: $segment) {
                ForEach(LibrarySegment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented).padding(14)
            if !missingAssets.isEmpty {
                NavigationLink { MissingFilesView() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("\(missingAssets.count) track file(s) missing")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.textSecondary)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 14).padding(.bottom, 8)
                }.buttonStyle(.plain)
            }
            content
        }
        .sonoraBackground()
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showImporter = true } label: { Image(systemName: "square.and.arrow.down") }
                    .accessibilityLabel("Import Music")
            }
        }
        .musicImporter(isPresented: $showImporter)
    }
    @ViewBuilder private var content: some View {
        switch segment {
        case .songs: SongsListView()
        case .albums: AlbumsListView()
        case .artists: ArtistsListView()
        case .playlists: PlaylistsView()
        case .favorites: FavoritesView()
        case .recent: RecentlyPlayedView()
        case .downloads: DownloadsView()
        }
    }
}
