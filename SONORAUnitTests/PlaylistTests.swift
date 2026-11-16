
import XCTest
import SwiftData
@testable import SONORA

@MainActor
final class PlaylistTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([TrackEntity.self, AlbumEntity.self, PlaylistEntity.self,
                             PlaylistItemEntity.self, ListeningHistoryEntity.self, LocalAssetEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }
    func testPlaylistPersistenceAndOrder() throws {
        let ctx = try makeContext()
        let playlist = PlaylistEntity(name: "Mix")
        ctx.insert(playlist)
        let t1 = TrackEntity(title: "One"); let t2 = TrackEntity(title: "Two")
        ctx.insert(t1); ctx.insert(t2)
        ctx.insert(PlaylistItemEntity(playlistID: playlist.id, trackID: t2.id, position: 1))
        ctx.insert(PlaylistItemEntity(playlistID: playlist.id, trackID: t1.id, position: 0))
        try ctx.save()
        let items = try ctx.fetch(FetchDescriptor<PlaylistItemEntity>(sortBy: [SortDescriptor(\.position)]))
        XCTAssertEqual(items.map { $0.trackID }, [t1.id, t2.id])
        let fetched = try ctx.fetch(FetchDescriptor<PlaylistEntity>())
        XCTAssertEqual(fetched.first?.name, "Mix")
    }
    func testFavoritePersists() throws {
        let ctx = try makeContext()
        let t = TrackEntity(title: "Fav", isFavorite: true)
        ctx.insert(t); try ctx.save()
        let favs = try ctx.fetch(FetchDescriptor<TrackEntity>(predicate: #Predicate { $0.isFavorite == true }))
        XCTAssertEqual(favs.count, 1)
    }
    func testDuplicateDetectionInputs() throws {
        let ctx = try makeContext()
        ctx.insert(TrackEntity(title: "Same", duration: 100, fileSizeBytes: 12345))
        try ctx.save()
        let all = try ctx.fetch(FetchDescriptor<TrackEntity>())
        let isDup = all.contains { $0.fileSizeBytes == 12345 && $0.title == "Same" && abs($0.duration - 100.5) < 1.5 }
        XCTAssertTrue(isDup)
    }
}
