# SONORA Data Model

This document describes a suggested local-first persistence model. Adapt
types to SwiftData or SQLite while preserving relationships and stable
identifiers.

## Track

-   id: UUID
-   title: String
-   artistName: String?
-   albumTitle: String?
-   albumArtist: String?
-   genre: String?
-   releaseYear: Int?
-   trackNumber: Int?
-   durationSeconds: Double?
-   sourceType: local \| online \| downloaded
-   localAssetID: UUID?
-   providerID: String?
-   providerTrackID: String?
-   artworkAssetID: UUID?
-   isFavorite: Bool
-   dateAdded: Date
-   lastPlayedAt: Date?
-   playCount: Int

Do not store expiring stream URLs as permanent identifiers.

## Album

-   id: UUID
-   title: String
-   artistName: String?
-   releaseYear: Int?
-   artworkAssetID: UUID?
-   providerID: String?
-   providerAlbumID: String?

## Artist

-   id: UUID
-   name: String
-   artworkAssetID: UUID?
-   biography: String?

## Playlist

-   id: UUID
-   name: String
-   descriptionText: String?
-   artworkAssetID: UUID?
-   createdAt: Date
-   updatedAt: Date
-   isCloudBacked: Bool

## PlaylistItem

-   id: UUID
-   playlistID: UUID
-   trackID: UUID
-   position: Int
-   addedAt: Date

Use an explicit join model so playlist order and duplicate entries can
be represented.

## ListeningHistoryEntry

-   id: UUID
-   trackID: UUID
-   playedAt: Date
-   listenedSeconds: Double

## LocalAsset

-   id: UUID
-   managedRelativePath: String?
-   originalFilename: String
-   contentType: String?
-   fileSizeBytes: Int64?
-   importedAt: Date
-   accessMode: managedCopy \| securityScopedBookmark
-   availabilityStatus: available \| missing \| inaccessible

Never assume a bookmark or external URL will remain valid forever.
Handle resolution failures.

## UserPreferences

-   appearance: system \| light \| dark
-   accentColor: String
-   autoplayEnabled: Bool
-   defaultShuffleEnabled: Bool
-   repeatMode: off \| one \| all
-   playbackSpeed: Double

## Queue persistence

Persist stable track references and queue order. Do not persist
temporary provider stream URLs as durable queue data.

## Data integrity

-   Use unique IDs.
-   Define delete behavior.
-   Prevent orphaned playlist items.
-   Add migrations for schema changes.
-   Keep local metadata available offline.
