import SwiftUI
import SwiftData

/// Manual metadata editor for a library track (FEATURES.md P1).
/// Edits are staged in local state and written to the TrackEntity only on Save,
/// so Cancel genuinely discards changes. Album groupings are reconciled after save.
struct EditTrackMetadataView: View {
    var track: TrackEntity
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var titleText = ""
    @State private var artistText = ""
    @State private var albumText = ""
    @State private var albumArtistText = ""
    @State private var genreText = ""
    @State private var yearText = ""
    @State private var trackNumberText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Track") {
                    TextField("Title", text: $titleText)
                    TextField("Artist", text: $artistText)
                    TextField("Album", text: $albumText)
                    TextField("Album Artist", text: $albumArtistText)
                }
                Section("Details") {
                    TextField("Genre", text: $genreText)
                    TextField("Release Year", text: $yearText)
                        .keyboardType(.numberPad)
                    TextField("Track Number", text: $trackNumberText)
                        .keyboardType(.numberPad)
                }
                Section("File") {
                    LabeledContent("Source", value: track.source.rawValue)
                    LabeledContent("Duration", value: DS.timeString(track.duration))
                    if let rel = track.localRelativePath {
                        Text(rel).font(.caption).foregroundStyle(DS.textSecondary)
                    }
                }
            }
            .scrollContentBackground(.hidden).sonoraBackground()
            .navigationTitle("Edit Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(titleText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                titleText = track.title
                artistText = track.artistName
                albumText = track.albumTitle
                albumArtistText = track.albumArtist ?? ""
                genreText = track.genre ?? ""
                yearText = track.releaseYear.map(String.init) ?? ""
                trackNumberText = track.trackNumber.map(String.init) ?? ""
            }
        }
    }

    private func save() {
        track.title = titleText.trimmingCharacters(in: .whitespaces)
        track.artistName = artistText.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown Artist" : artistText
        track.albumTitle = albumText.trimmingCharacters(in: .whitespaces).isEmpty ? "Unknown Album" : albumText
        track.albumArtist = albumArtistText.isEmpty ? nil : albumArtistText
        track.genre = genreText.isEmpty ? nil : genreText
        track.releaseYear = Int(yearText)
        track.trackNumber = Int(trackNumberText)
        try? context.save()
        LocalMusicService.reconcileAlbums(in: context)
        dismiss()
    }
}
