
import SwiftUI

struct MiniPlayerView: View {
    @Environment(PlaybackManager.self) private var playback
    var onTap: () -> Void
    var body: some View {
        if let track = playback.currentTrack {
            HStack(spacing: 12) {
                ArtworkView(data: track.artworkData, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary).lineLimit(1)
                    Text(track.artistName).font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                }
                Spacer()
                Button { playback.togglePlayPause() } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill").font(.title3).foregroundStyle(DS.textPrimary)
                }.accessibilityLabel(playback.isPlaying ? "Pause" : "Play")
                Button { playback.next() } label: {
                    Image(systemName: "forward.fill").foregroundStyle(DS.textPrimary)
                }.accessibilityLabel("Next Track")
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .background(DS.surface.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 10).padding(.bottom, 4)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .overlay(alignment: .bottom) {
                ProgressView(value: playback.progress).tint(DS.accent).padding(.horizontal, 22)
            }
        }
    }
}
