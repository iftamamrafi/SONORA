
import Foundation

enum TrackSource: String, Codable, CaseIterable {
    case local = "LOCAL"
    case online = "ONLINE"
    case downloaded = "DOWNLOADED"
}

enum RepeatMode: String, Codable, CaseIterable {
    case off, all, one
    var next: RepeatMode {
        switch self { case .off: return .all; case .all: return .one; case .one: return .off }
    }
    var iconName: String {
        switch self { case .off: return "repeat"; case .all: return "repeat"; case .one: return "repeat.1" }
    }
}

enum AppearanceMode: String, Codable, CaseIterable {
    case system, light, dark
    var label: String { rawValue.capitalized }
}

/// Value-type snapshot of a track used by the playback engine and queue.
/// Decoupled from SwiftData so playback and queue logic stay testable.
struct TrackSnapshot: Identifiable, Equatable, Codable {
    var id: UUID
    var title: String
    var artistName: String
    var albumTitle: String
    var genre: String?
    var duration: Double
    var source: TrackSource
    var localRelativePath: String?      // relative to Documents
    var streamURLString: String?        // remote stream (provider / demo)
    var providerName: String?
    var providerTrackID: String?
    var isDemo: Bool = false
    var downloadable: Bool = false
    var artworkData: Data?

    static func == (lhs: TrackSnapshot, rhs: TrackSnapshot) -> Bool { lhs.id == rhs.id }

    var localFileURL: URL? {
        guard let rel = localRelativePath else { return nil }
        return FileManager.default.documentsDirectory.appendingPathComponent(rel)
    }
    var playbackURL: URL? {
        if let f = localFileURL { return f }
        if let s = streamURLString { return URL(string: s) }
        return nil
    }
    var isLocalFile: Bool { localRelativePath != nil }
}

struct GenreItem: Identifiable {
    var id: String { name }
    var name: String
    var icon: String
    static let all: [GenreItem] = [
        GenreItem(name: "Pop", icon: "star.fill"),
        GenreItem(name: "Rock", icon: "guitars.fill"),
        GenreItem(name: "Electronic", icon: "waveform.path.ecg"),
        GenreItem(name: "Jazz", icon: "music.note"),
        GenreItem(name: "Classical", icon: "pianokeys"),
        GenreItem(name: "Hip-Hop", icon: "mic.fill"),
        GenreItem(name: "Ambient", icon: "cloud.fill"),
        GenreItem(name: "Acoustic", icon: "music.quarternote.3")
    ]
}

extension FileManager {
    /// Documents directory without force-unwrapping (the temporary-directory fallback
    /// never happens in practice on iOS, but avoids a crash path entirely).
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask).first ?? temporaryDirectory
    }
}

enum SonoraError: LocalizedError {
    case fileMissing(String)
    case unsupportedFormat(String)
    case providerUnavailable
    case networkUnavailable
    case playbackFailed(String)
    case importFailed(String)
    var errorDescription: String? {
        switch self {
        case .fileMissing(let n): return "The file for \u{201C}\(n)\u{201D} is missing or was moved."
        case .unsupportedFormat(let n): return "\u{201C}\(n)\u{201D} is in a format SONORA cannot play."
        case .providerUnavailable: return "No online music provider is available right now."
        case .networkUnavailable: return "You appear to be offline. Local music is still available."
        case .playbackFailed(let m): return "Playback failed: \(m)"
        case .importFailed(let m): return "Import failed: \(m)"
        }
    }
}
