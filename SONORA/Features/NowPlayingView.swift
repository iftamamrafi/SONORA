
import SwiftUI
import SwiftData

struct NowPlayingView: View {
    @Binding var isPresented: Bool
    @Environment(PlaybackManager.self) private var playback
    @Environment(\.modelContext) private var context
    @Query private var allTracks: [TrackEntity]
    @State private var scrubValue: Double?
    @State private var showQueue = false
    @State private var editingTrack: TrackEntity? = nil
    @State private var showLyrics = false
    @State private var showEQ = false
    @State private var showSleepTimer = false

    private var track: TrackSnapshot? { playback.currentTrack }
    private var isFavorite: Bool {
        guard let t = track else { return false }
        return allTracks.first { $0.id == t.id }?.isFavorite ?? false
    }
    private var bgColor: Color { ArtworkColor.averageColor(from: track?.artworkData) }
    private var currentEntity: TrackEntity? {
        guard let t = track else { return nil }
        return allTracks.first { $0.id == t.id }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [bgColor.opacity(0.85), DS.background], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if let track {
                VStack(spacing: 20) {
                    topBar
                    ArtworkView(data: track.artworkData, size: 300, corner: 20)
                        .shadow(radius: 30)
                        .scaleEffect(playback.isPlaying ? 1.0 : 0.94)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: playback.isPlaying)
                    titleRow(track)
                    progressSection
                    controls
                    volumeRow
                    bottomActions
                    if let err = playback.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 26).padding(.top, 10)
            } else {
                EmptyStateView(icon: "music.note", title: "Nothing playing", message: "Pick a song from your library to start listening.")
            }
        }
        .sheet(isPresented: $showQueue) { NavigationStack { QueueView() } }
        .sheet(item: $editingTrack) { entity in EditTrackMetadataView(track: entity) }
        .sheet(isPresented: $showLyrics) { NavigationStack { LyricsView() } }
        .sheet(isPresented: $showEQ) { NavigationStack { EqualizerView() } }
        .confirmationDialog("Sleep Timer", isPresented: $showSleepTimer) {
            ForEach([15.0, 30.0, 45.0, 60.0], id: \.self) { m in
                Button("\(Int(m)) minutes") { playback.setSleepTimer(minutes: m) }
            }
            Button("Custom — 90 minutes") { playback.setSleepTimer(minutes: 90) }
            Button("Cancel Timer", role: .destructive) { playback.cancelSleepTimer() }
            Button("Close", role: .cancel) {}
        }
    }
    private var topBar: some View {
        HStack {
            Button { isPresented = false } label: { Image(systemName: "chevron.down").font(.title3) }
                .foregroundStyle(DS.textPrimary).accessibilityLabel("Close")
            Spacer()
            VStack(spacing: 2) {
                Text("NOW PLAYING").font(.caption2.bold()).tracking(2).foregroundStyle(DS.textSecondary)
                if let track { SourceBadge(source: track.source, isDemo: track.isDemo) }
            }
            Spacer()
            Button { showSleepTimer = true } label: {
                Image(systemName: playback.sleepTimerRemaining != nil ? "moon.fill" : "moon")
                    .foregroundStyle(playback.sleepTimerRemaining != nil ? DS.accent : DS.textPrimary)
            }.accessibilityLabel("Sleep Timer")
            if currentEntity != nil {
                Menu {
                    Button { editingTrack = currentEntity } label: { Label("Edit Metadata", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle").font(.title3) }
                .foregroundStyle(DS.textPrimary)
                .accessibilityLabel("Track Options")
            }
        }
    }
    private func titleRow(_ track: TrackSnapshot) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title).font(.title3.bold()).foregroundStyle(.white).lineLimit(2)
                Text(track.artistName).font(.body).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                Text(track.albumTitle).font(.caption).foregroundStyle(.white.opacity(0.5)).lineLimit(1)
            }
            Spacer()
            Button { toggleFavorite(track) } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3).foregroundStyle(isFavorite ? DS.accent : .white)
            }.accessibilityLabel("Favorite")
        }
    }
    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(value: Binding(get: { scrubValue ?? playback.currentTime },
                                  set: { scrubValue = $0 }),
                   in: 0...max(playback.duration, 1)) { editing in
                if !editing, let v = scrubValue { playback.seek(to: v); scrubValue = nil }
            }
            .tint(DS.accent)
            HStack {
                Text(DS.timeString(scrubValue ?? playback.currentTime))
                Spacer()
                if let remaining = playback.sleepTimerRemaining {
                    Text("Sleep in \(DS.timeString(remaining))").foregroundStyle(DS.accent)
                    Spacer()
                }
                Text("-" + DS.timeString(max(playback.duration - playback.currentTime, 0)))
            }
            .font(.caption).foregroundStyle(.white.opacity(0.7)).monospacedDigit()
        }
    }
    private var controls: some View {
        HStack(spacing: 28) {
            Button { playback.toggleShuffle() } label: {
                Image(systemName: "shuffle").foregroundStyle(playback.queue.isShuffled ? DS.accent : .white.opacity(0.8))
            }.accessibilityLabel("Shuffle")
            Button { playback.previous() } label: { Image(systemName: "backward.fill").font(.title) }
                .foregroundStyle(.white).accessibilityLabel("Previous")
            Button { playback.togglePlayPause() } label: {
                Image(systemName: playback.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 64))
            }.foregroundStyle(.white).accessibilityLabel(playback.isPlaying ? "Pause" : "Play")
            Button { playback.next() } label: { Image(systemName: "forward.fill").font(.title) }
                .foregroundStyle(.white).accessibilityLabel("Next")
            Button { playback.cycleRepeat() } label: {
                Image(systemName: playback.queue.repeatMode.iconName)
                    .foregroundStyle(playback.queue.repeatMode != .off ? DS.accent : .white.opacity(0.8))
            }.accessibilityLabel("Repeat")
        }
    }
    private var volumeRow: some View {
        HStack(spacing: 12) {
            Button { playback.isMuted.toggle() } label: {
                Image(systemName: playback.isMuted ? "speaker.slash.fill" : "speaker.fill")
            }.foregroundStyle(.white.opacity(0.8))
            Slider(value: Binding(get: { Double(playback.volume) }, set: { playback.volume = Float($0) }), in: 0...1)
                .tint(.white.opacity(0.8))
            Image(systemName: "speaker.wave.3.fill").foregroundStyle(.white.opacity(0.8))
        }
    }
    private var bottomActions: some View {
        HStack(spacing: 36) {
            Button { showLyrics = true } label: { Label("Lyrics", systemImage: "quote.bubble") }
            Button { showEQ = true } label: { Label("EQ", systemImage: "slider.vertical.3") }
            Button { showQueue = true } label: { Label("Queue", systemImage: "list.bullet") }
        }
        .font(.subheadline).foregroundStyle(.white.opacity(0.9))
    }
    private func toggleFavorite(_ track: TrackSnapshot) {
        if let entity = allTracks.first(where: { $0.id == track.id }) {
            entity.isFavorite.toggle()
        } else {
            let entity = TrackEntity(id: track.id, title: track.title, artistName: track.artistName,
                                     albumTitle: track.albumTitle, genre: track.genre, duration: track.duration,
                                     sourceRaw: track.source.rawValue, providerID: track.providerName,
                                     providerTrackID: track.providerTrackID, streamURLString: track.streamURLString,
                                     isFavorite: true, artworkData: track.artworkData)
            context.insert(entity)
        }
        try? context.save()
    }
}
