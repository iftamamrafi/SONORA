
import Foundation

protocol MusicProvider: Sendable {
    var providerName: String { get }
    var isConfigured: Bool { get }
    func search(query: String) async throws -> [TrackSnapshot]
    func trending() async throws -> [TrackSnapshot]
    func newReleases() async throws -> [TrackSnapshot]
    func streamURL(for track: TrackSnapshot) async throws -> URL
}

/// Clearly-labeled demo provider using SoundHelix test audio, which is
/// published by its author for testing/demonstration purposes.
final class DemoMusicProvider: MusicProvider {
    let providerName = "Demo (SoundHelix test audio)"
    var isConfigured: Bool { true }

    private func demoTrack(_ n: Int, title: String, genre: String, duration: Double) -> TrackSnapshot {
        TrackSnapshot(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n)) ?? UUID(),
                      title: title, artistName: "SoundHelix (Test Audio)", albumTitle: "Demo Test Tracks",
                      genre: genre, duration: duration, source: .online, localRelativePath: nil,
                      streamURLString: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-\(n).mp3",
                      providerName: providerName, providerTrackID: "soundhelix-\(n)",
                      isDemo: true, downloadable: true, artworkData: nil)
    }
    private var catalogue: [TrackSnapshot] {
        [demoTrack(1, title: "SoundHelix Song 1 — Demo", genre: "Electronic", duration: 372),
         demoTrack(2, title: "SoundHelix Song 2 — Demo", genre: "Pop", duration: 425),
         demoTrack(3, title: "SoundHelix Song 3 — Demo", genre: "Rock", duration: 367),
         demoTrack(4, title: "SoundHelix Song 4 — Demo", genre: "Jazz", duration: 322),
         demoTrack(5, title: "SoundHelix Song 5 — Demo", genre: "Classical", duration: 385),
         demoTrack(6, title: "SoundHelix Song 6 — Demo", genre: "Ambient", duration: 352)]
    }
    func search(query: String) async throws -> [TrackSnapshot] {
        let q = query.lowercased()
        if q.isEmpty { return catalogue }
        return catalogue.filter { $0.title.lowercased().contains(q) || ($0.genre ?? "").lowercased().contains(q) || $0.artistName.lowercased().contains(q) }
    }
    func trending() async throws -> [TrackSnapshot] { Array(catalogue.prefix(4)) }
    func newReleases() async throws -> [TrackSnapshot] { Array(catalogue.suffix(3)) }
    func streamURL(for track: TrackSnapshot) async throws -> URL {
        guard let s = track.streamURLString, let url = URL(string: s) else { throw SonoraError.providerUnavailable }
        return url
    }
}

/// Used when the user disables the provider: online sections show an explicit unavailable state.
final class UnavailableProvider: MusicProvider {
    let providerName = "No provider configured"
    var isConfigured: Bool { false }
    func search(query: String) async throws -> [TrackSnapshot] { throw SonoraError.providerUnavailable }
    func trending() async throws -> [TrackSnapshot] { throw SonoraError.providerUnavailable }
    func newReleases() async throws -> [TrackSnapshot] { throw SonoraError.providerUnavailable }
    func streamURL(for track: TrackSnapshot) async throws -> URL { throw SonoraError.providerUnavailable }
}
