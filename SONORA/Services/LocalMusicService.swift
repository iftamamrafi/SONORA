
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct ImportResult {
    var imported: Int = 0
    var duplicates: Int = 0
    var failed: Int = 0
    var messages: [String] = []
}

enum LocalMusicService {
    static var musicFolder: URL {
        let dir = FileManager.default.documentsDirectory.appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static var downloadsFolder: URL {
        let dir = FileManager.default.documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static let supportedTypes: [UTType] = {
        var types: [UTType] = [.mp3, .mpeg4Audio, .wav, .aiff, .audio]
        if let flac = UTType(filenameExtension: "flac") { types.append(flac) }
        if let alac = UTType(filenameExtension: "m4a") { types.append(alac) }
        if let caf = UTType(filenameExtension: "caf") { types.append(caf) }
        return types
    }()
    static let supportedExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "alac", "caf"]

    /// Imports picked files: copies into Documents/Music, extracts metadata, detects duplicates
    /// by file size + title + duration. Runs metadata work off the main thread.
    @MainActor
    static func importFiles(_ urls: [URL], into context: ModelContext) async -> ImportResult {
        var result = ImportResult()
        var known = (try? context.fetch(FetchDescriptor<TrackEntity>())) ?? []
        for src in urls {
            let scoped = src.startAccessingSecurityScopedResource()
            defer { if scoped { src.stopAccessingSecurityScopedResource() } }
            let ext = src.pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else {
                result.failed += 1; result.messages.append("\(src.lastPathComponent): unsupported format"); continue
            }
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: src.path)
                let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
                let destName = UUID().uuidString + "-" + src.lastPathComponent
                let dest = musicFolder.appendingPathComponent(destName)
                try FileManager.default.copyItem(at: src, to: dest)
                let meta = await MetadataService.extract(from: dest, fileSize: size)
                let isDup = known.contains { $0.fileSizeBytes == size && $0.title == meta.title && abs($0.duration - meta.duration) < 1.5 }
                if isDup {
                    try? FileManager.default.removeItem(at: dest)
                    result.duplicates += 1; result.messages.append("\(meta.title): duplicate skipped"); continue
                }
                let rel = "Music/" + destName
                let track = TrackEntity(title: meta.title, artistName: meta.artistName, albumTitle: meta.albumTitle,
                                        albumArtist: meta.albumArtist, genre: meta.genre, releaseYear: meta.releaseYear,
                                        trackNumber: meta.trackNumber, duration: meta.duration,
                                        sourceRaw: TrackSource.local.rawValue, localRelativePath: rel,
                                        fileSizeBytes: size, artworkData: meta.artworkData)
                context.insert(track)
                known.append(track)
                context.insert(LocalAssetEntity(managedRelativePath: rel, originalFilename: src.lastPathComponent,
                                                contentType: ext, fileSizeBytes: size))
                upsertAlbum(for: track, in: context)
                result.imported += 1
            } catch {
                result.failed += 1; result.messages.append("\(src.lastPathComponent): \(error.localizedDescription)")
            }
        }
        try? context.save()
        return result
    }

    @MainActor
    static func upsertAlbum(for track: TrackEntity, in context: ModelContext) {
        let title = track.albumTitle
        let albums = (try? context.fetch(FetchDescriptor<AlbumEntity>())) ?? []
        if let album = albums.first(where: { $0.title == title && $0.artistName == track.artistName }) {
            album.trackCount += 1
            if album.artworkData == nil { album.artworkData = track.artworkData }
        } else {
            context.insert(AlbumEntity(title: title, artistName: track.artistName,
                                       releaseYear: track.releaseYear, trackCount: 1, artworkData: track.artworkData))
        }
    }

    /// On launch: verifies that each managed local file still exists. The file-existence
    /// checks run off the main thread; results are applied to LocalAssetEntity rows
    /// (availabilityRaw = "available" / "missing") on the main actor. Library surfaces
    /// missing files in MissingFilesView with a Remove action.
    @MainActor
    static func verifyAvailability(in context: ModelContext) {
        let assets = (try? context.fetch(FetchDescriptor<LocalAssetEntity>())) ?? []
        let docs = FileManager.default.documentsDirectory
        let checks: [(UUID, String)] = assets.compactMap { asset in
            guard let rel = asset.managedRelativePath else { return nil }
            return (asset.id, docs.appendingPathComponent(rel).path)
        }
        guard !checks.isEmpty else { return }
        Task.detached(priority: .utility) {
            var results: [UUID: Bool] = [:]
            for (id, path) in checks { results[id] = FileManager.default.fileExists(atPath: path) }
            await MainActor.run {
                let fresh = (try? context.fetch(FetchDescriptor<LocalAssetEntity>())) ?? []
                var changed = false
                for asset in fresh {
                    guard let exists = results[asset.id] else { continue }
                    let newValue = exists ? "available" : "missing"
                    if asset.availabilityRaw != newValue { asset.availabilityRaw = newValue; changed = true }
                }
                if changed { try? context.save() }
            }
        }
    }

    /// Rebuilds AlbumEntity rows from the current library tracks so album counts and
    /// artwork stay correct after metadata edits or track removal.
    @MainActor
    static func reconcileAlbums(in context: ModelContext) {
        let tracks = ((try? context.fetch(FetchDescriptor<TrackEntity>())) ?? [])
            .filter { $0.source != .online || $0.localRelativePath != nil }
        let old = (try? context.fetch(FetchDescriptor<AlbumEntity>())) ?? []
        old.forEach { context.delete($0) }
        var grouped: [String: [TrackEntity]] = [:]
        for t in tracks { grouped[t.albumTitle + "\u{1F}" + t.artistName, default: []].append(t) }
        for group in grouped.values {
            guard let first = group.first else { continue }
            context.insert(AlbumEntity(title: first.albumTitle, artistName: first.artistName,
                                       releaseYear: group.compactMap { $0.releaseYear }.first,
                                       trackCount: group.count,
                                       artworkData: group.compactMap { $0.artworkData }.first))
        }
        try? context.save()
    }

    /// Removes a track and everything that references it (playlist items, its local
    /// asset row). Does not delete the audio file itself.
    @MainActor
    static func deleteTrack(_ track: TrackEntity, in context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<PlaylistItemEntity>())) ?? []
        items.filter { $0.trackID == track.id }.forEach { context.delete($0) }
        if let rel = track.localRelativePath {
            let assets = (try? context.fetch(FetchDescriptor<LocalAssetEntity>())) ?? []
            assets.filter { $0.managedRelativePath == rel }.forEach { context.delete($0) }
        }
        context.delete(track)
        try? context.save()
    }
    static func fileExists(_ track: TrackSnapshot) -> Bool {
        guard let url = track.localFileURL else { return track.streamURLString != nil }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
