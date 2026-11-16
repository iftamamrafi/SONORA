
import Foundation
import AVFoundation
import UIKit

struct ExtractedMetadata {
    var title: String
    var artistName: String
    var albumTitle: String
    var albumArtist: String?
    var genre: String?
    var releaseYear: Int?
    var trackNumber: Int?
    var duration: Double
    var artworkData: Data?
    var lyrics: String?
    var fileSizeBytes: Int64
}

enum MetadataService {
    /// Extracts metadata off the calling thread using AVAsset loading.
    static func extract(from url: URL, fileSize: Int64) async -> ExtractedMetadata {
        let asset = AVURLAsset(url: url)
        var duration: Double = 0
        if let d = try? await asset.load(.duration) { duration = CMTimeGetSeconds(d) }
        if !duration.isFinite { duration = 0 }
        var meta = ExtractedMetadata(title: url.deletingPathExtension().lastPathComponent,
                                     artistName: "Unknown Artist", albumTitle: "Unknown Album",
                                     duration: duration, fileSizeBytes: fileSize)
        guard let items = try? await asset.load(.metadata) else { return meta }
        for item in items {
            guard let key = item.commonKey?.rawValue else {
                if item.identifier?.rawValue.lowercased().contains("lyr") == true {
                    if let s = try? await item.load(.stringValue) { meta.lyrics = s }
                }
                continue
            }
            switch key {
            case "title": if let v = try? await item.load(.stringValue), !v.isEmpty { meta.title = v }
            case "artist": if let v = try? await item.load(.stringValue), !v.isEmpty { meta.artistName = v }
            case "albumName": if let v = try? await item.load(.stringValue), !v.isEmpty { meta.albumTitle = v }
            case "type": if let v = try? await item.load(.stringValue) { meta.genre = v }
            case "artwork": if let v = try? await item.load(.dataValue) { meta.artworkData = v }
            default: break
            }
        }
        return meta
    }

    static func defaults(for filename: String) -> (title: String, artist: String, album: String) {
        (filename, "Unknown Artist", "Unknown Album")
    }
}
