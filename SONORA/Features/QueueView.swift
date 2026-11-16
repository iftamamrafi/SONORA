
import SwiftUI

struct QueueView: View {
    @Environment(PlaybackManager.self) private var playback
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        List {
            if let current = playback.currentTrack {
                Section("Now Playing") {
                    SongRow(track: current, isCurrent: true) {}
                        .listRowBackground(DS.surface)
                }
            }
            Section {
                ForEach(playback.queue.upcoming) { track in
                    SongRow(track: track) { playback.jumpToQueueItem(track) }
                        .listRowBackground(DS.secondaryBackground)
                }
                .onDelete { idx in
                    let upcoming = playback.queue.upcoming
                    idx.forEach { playback.removeFromQueue(upcoming[$0]) }
                }
                .onMove { from, to in
                    // Map visible upcoming indices to item indices for the pure queue move.
                    let upcoming = playback.queue.upcoming
                    guard let src = from.first, src < upcoming.count,
                          let srcItemIdx = playback.queue.items.firstIndex(of: upcoming[src]) else { return }
                    let destItemIdx: Int
                    if to >= upcoming.count, let last = upcoming.last, let li = playback.queue.items.firstIndex(of: last) {
                        destItemIdx = li + 1
                    } else if to < upcoming.count, let di = playback.queue.items.firstIndex(of: upcoming[to]) {
                        destItemIdx = di
                    } else { destItemIdx = playback.queue.items.count }
                    playback.queue.moveItem(from: srcItemIdx, to: destItemIdx)
                }
            } header: {
                HStack {
                    Text("Up Next (\(playback.queue.upcoming.count))")
                    Spacer()
                    Button("Clear") { playback.clearQueue() }.font(.caption)
                }
            }
            if playback.queue.isShuffled {
                Text("Shuffle is on — order reflects the shuffled play order.").font(.caption).foregroundStyle(DS.textSecondary)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle("Queue")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
        }
    }
}
