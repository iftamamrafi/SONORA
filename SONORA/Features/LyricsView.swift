
import SwiftUI

struct LyricsView: View {
    @Environment(PlaybackManager.self) private var playback
    @Environment(\.dismiss) private var dismiss
    @State private var synced: [LyriTimber] = []
    @State private var plain: String?
    @State private var loadedTrackID: UUID?
    private var currentIndex: Int? {
        guard !synced.isEmpty else { return nil }
        return LRCParser.index(ofCurrentLine: synced, at: playback.currentTime)
    }
    var body: some View {
        Group {
            if !synced.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(synced.enumerated()), id: \.offset) { idx, line in
                                Text(line.text.isEmpty ? "♪" : line.text)
                                    .font(.title3.weight(idx == currentIndex ? .bold : .regular))
                                    .foregroundStyle(idx == currentIndex ? DS.accent : DS.textSecondary)
                                    .id(idx)
                                    .onTapGesture { playback.seek(to: line.time) }
                            }
                        }
                        .padding(22)
                    }
                    .onChange(of: currentIndex) { _, newValue in
                        if let newValue { withAnimation { proxy.scrollTo(newValue, anchor: .center) } }
                    }
                }
            } else if let plain {
                ScrollView { Text(plain).font(.body).foregroundStyle(DS.textPrimary).padding(22) }
            } else {
                EmptyStateView(icon: "quote.bubble", title: "No lyrics available",
                               message: "Lyrics appear when they are embedded in the audio file or a matching .lrc file sits next to the imported track. SONORA never fabricates lyrics.")
            }
        }
        .sonoraBackground()
        .navigationTitle("Lyrics")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .task(id: playback.currentTrack?.id) { await load() }
    }
    private func load() async {
        guard let track = playback.currentTrack else { return }
        loadedTrackID = track.id
        let result = await LyricsService.lyrics(for: track)
        if loadedTrackID == track.id { synced = result.synced; plain = result.plain }
    }
}
