
import Foundation
import UIKit

/// Simple in-memory artwork cache; images are also stored on TrackEntity (external storage).
final class ArtworkCache: @unchecked Sendable { // NSCache is thread-safe
    static let shared = ArtworkCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 200 }
    func image(for key: UUID, data: Data?) -> UIImage? {
        let k = key.uuidString as NSString
        if let img = cache.object(forKey: k) { return img }
        guard let data, let img = UIImage(data: data) else { return nil }
        cache.setObject(img, forKey: k)
        return img
    }
    func clear() { cache.removeAllObjects() }
    static func clearArtworkFiles() {
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let dir = caches.appendingPathComponent("Artwork")
            try? FileManager.default.removeItem(at: dir)
        }
        shared.clear()
    }
    static func storageUsage() -> (music: Int64, downloads: Int64) {
        func size(of dir: URL) -> Int64 {
            guard let files = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
            var total: Int64 = 0
            for case let f as URL in files { total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
            return total
        }
        return (size(of: LocalMusicService.musicFolder), size(of: LocalMusicService.downloadsFolder))
    }
}
