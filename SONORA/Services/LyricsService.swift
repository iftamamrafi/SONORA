
import Foundation
import AVFoundation

enum LyricsService {
    /// Embedded lyrics from the audio asset, else sidecar .lrc next to the managed copy, else plain embedded text.
    static func lyrics(for track: TrackSnapshot) async -> (synced: [LyriTimber], plain: String?) {
        if let fileURL = track.localFileURL {
            // Sidecar LRC
            let lrcURL = fileURL.deletingPathExtension().appendingPathExtension("lrc")
            if let text = try? String(contentsOf: lrcURL, encoding: .utf8) {
                let lines = LRCParser.parse(text)
                if !lines.isEmpty { return (lines, nil) }
            }
            let asset = AVURLAsset(url: fileURL)
            if let items = try? await asset.load(.metadata) {
                for item in items {
                    let idf = item.identifier
                    if idf.lowercased().contains("lyr") {
                        if let s = try? await item.load(.stringValue), !s.isEmpty {
                            let lines = LRCParser.parse(s)
                            return lines.isEmpty ? ([], s) : (lines, nil)
                        }
                    }
                }
            }
        }
        return ([], nil)
    }
}
