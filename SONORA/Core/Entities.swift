
import Foundation
import SwiftData

@Model
final class TrackEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var artistName: String
    var albumTitle: String
    var albumArtist: String?
    var genre: String?
    var releaseYear: Int?
    var trackNumber: Int?
    var duration: Double
    var sourceRaw: String
    var localRelativePath: String?
    var providerID: String?
    var providerTrackID: String?
    var streamURLString: String?
    var isFavorite: Bool
    var dateAdded: Date
    var lastPlayedAt: Date?
    var playCount: Int
    var fileSizeBytes: Int64
    @Attribute(.externalStorage) var artworkData: Data?

    init(id: UUID = UUID(), title: String, artistName: String = "Unknown Artist",
         albumTitle: String = "Unknown Album", albumArtist: String? = nil, genre: String? = nil,
         releaseYear: Int? = nil, trackNumber: Int? = nil, duration: Double = 0,
         sourceRaw: String = TrackSource.local.rawValue, localRelativePath: String? = nil,
         providerID: String? = nil, providerTrackID: String? = nil, streamURLString: String? = nil,
         isFavorite: Bool = false, dateAdded: Date = Date(), lastPlayedAt: Date? = nil,
         playCount: Int = 0, fileSizeBytes: Int64 = 0, artworkData: Data? = nil) {
        self.id = id; self.title = title; self.artistName = artistName
        self.albumTitle = albumTitle; self.albumArtist = albumArtist; self.genre = genre
        self.releaseYear = releaseYear; self.trackNumber = trackNumber; self.duration = duration
        self.sourceRaw = sourceRaw; self.localRelativePath = localRelativePath
        self.providerID = providerID; self.providerTrackID = providerTrackID
        self.streamURLString = streamURLString; self.isFavorite = isFavorite
        self.dateAdded = dateAdded; self.lastPlayedAt = lastPlayedAt; self.playCount = playCount
        self.fileSizeBytes = fileSizeBytes; self.artworkData = artworkData
    }

    var source: TrackSource { TrackSource(rawValue: sourceRaw) ?? .local }

    func snapshot() -> TrackSnapshot {
        TrackSnapshot(id: id, title: title, artistName: artistName, albumTitle: albumTitle,
                      genre: genre, duration: duration, source: source,
                      localRelativePath: localRelativePath, streamURLString: streamURLString,
                      providerName: providerID, providerTrackID: providerTrackID,
                      isDemo: providerID?.contains("Demo") ?? false,
                      downloadable: source == .online, artworkData: artworkData)
    }
}

@Model
final class AlbumEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var artistName: String
    var releaseYear: Int?
    var trackCount: Int
    @Attribute(.externalStorage) var artworkData: Data?
    init(id: UUID = UUID(), title: String, artistName: String, releaseYear: Int? = nil,
         trackCount: Int = 0, artworkData: Data? = nil) {
        self.id = id; self.title = title; self.artistName = artistName
        self.releaseYear = releaseYear; self.trackCount = trackCount; self.artworkData = artworkData
    }
}

@Model
final class PlaylistEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String
    var createdAt: Date
    var updatedAt: Date
    @Attribute(.externalStorage) var artworkData: Data?
    init(id: UUID = UUID(), name: String, detail: String = "", createdAt: Date = Date(),
         updatedAt: Date = Date(), artworkData: Data? = nil) {
        self.id = id; self.name = name; self.detail = detail
        self.createdAt = createdAt; self.updatedAt = updatedAt; self.artworkData = artworkData
    }
}

@Model
final class PlaylistItemEntity {
    @Attribute(.unique) var id: UUID
    var playlistID: UUID
    var trackID: UUID
    var position: Int
    var addedAt: Date
    init(id: UUID = UUID(), playlistID: UUID, trackID: UUID, position: Int, addedAt: Date = Date()) {
        self.id = id; self.playlistID = playlistID; self.trackID = trackID
        self.position = position; self.addedAt = addedAt
    }
}

@Model
final class ListeningHistoryEntity {
    @Attribute(.unique) var id: UUID
    var trackID: UUID
    var trackTitle: String
    var playedAt: Date
    var listenedSeconds: Double
    init(id: UUID = UUID(), trackID: UUID, trackTitle: String, playedAt: Date = Date(), listenedSeconds: Double = 0) {
        self.id = id; self.trackID = trackID; self.trackTitle = trackTitle
        self.playedAt = playedAt; self.listenedSeconds = listenedSeconds
    }
}

@Model
final class LocalAssetEntity {
    @Attribute(.unique) var id: UUID
    var managedRelativePath: String?
    var originalFilename: String
    var contentType: String?
    var fileSizeBytes: Int64
    var importedAt: Date
    var availabilityRaw: String
    init(id: UUID = UUID(), managedRelativePath: String? = nil, originalFilename: String,
         contentType: String? = nil, fileSizeBytes: Int64 = 0, importedAt: Date = Date(),
         availabilityRaw: String = "available") {
        self.id = id; self.managedRelativePath = managedRelativePath
        self.originalFilename = originalFilename; self.contentType = contentType
        self.fileSizeBytes = fileSizeBytes; self.importedAt = importedAt
        self.availabilityRaw = availabilityRaw
    }
}
