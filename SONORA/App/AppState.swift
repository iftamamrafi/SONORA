
import Foundation
import SwiftData

@MainActor
@Observable
final class AppState {
    let container: ModelContainer
    let playback = PlaybackManager()
    let preferences = PreferencesStore()
    let network = NetworkMonitor()
    let downloads = DownloadManager()
    var provider: MusicProvider

    init() {
        let schema = Schema([TrackEntity.self, AlbumEntity.self, PlaylistEntity.self,
                             PlaylistItemEntity.self, ListeningHistoryEntity.self, LocalAssetEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            container = c
        } else {
            // Fallback: in-memory container so the app still launches if the store is corrupt.
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [mem])
        }
        provider = preferences.providerEnabled ? DemoMusicProvider() : UnavailableProvider()
        playback.eqEnabled = preferences.eqEnabled
        playback.eqGains = currentEQGains()
        playback.playbackSpeed = preferences.playbackSpeed
        playback.queue.repeatMode = preferences.defaultRepeat
        if preferences.defaultShuffle { playback.queue.setShuffle(true) }
        downloads.modelContext = container.mainContext
        LocalMusicService.verifyAvailability(in: container.mainContext)
        wireHistoryCallbacks()
    }

    func refreshProvider() {
        provider = preferences.providerEnabled ? DemoMusicProvider() : UnavailableProvider()
    }
    func currentEQGains() -> [Float] {
        if preferences.eqPresetName == "Custom" { return preferences.eqCustomGains.map { Float($0) } }
        return EQPreset.named(preferences.eqPresetName).gains
    }
    func applyEQSettings() {
        playback.eqEnabled = preferences.eqEnabled
        playback.eqGains = currentEQGains()
    }
    private func wireHistoryCallbacks() {
        let ctx = container.mainContext
        playback.onTrackStarted = { track in
            let descriptor = FetchDescriptor<TrackEntity>()
            if let all = try? ctx.fetch(descriptor), let entity = all.first(where: { $0.id == track.id }) {
                entity.playCount += 1
                entity.lastPlayedAt = Date()
                try? ctx.save()
            }
            ctx.insert(ListeningHistoryEntity(trackID: track.id, trackTitle: track.title))
            try? ctx.save()
        }
        playback.onListeningProgress = { _, _ in try? ctx.save() }
    }
    /// Persists a downloaded/online snapshot into the library if missing (used when favoriting demo tracks).
    func ensureEntity(for track: TrackSnapshot, in context: ModelContext) -> TrackEntity {
        let all = (try? context.fetch(FetchDescriptor<TrackEntity>())) ?? []
        if let found = all.first(where: { $0.id == track.id }) { return found }
        let entity = TrackEntity(id: track.id, title: track.title, artistName: track.artistName,
                                 albumTitle: track.albumTitle, genre: track.genre, duration: track.duration,
                                 sourceRaw: track.source.rawValue, localRelativePath: track.localRelativePath,
                                 providerID: track.providerName, providerTrackID: track.providerTrackID,
                                 streamURLString: track.streamURLString, artworkData: track.artworkData)
        context.insert(entity)
        try? context.save()
        return entity
    }
}
