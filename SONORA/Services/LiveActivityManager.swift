
import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<NowPlayingActivityAttributes>?
    private init() {}
    func update(track: TrackSnapshot, isPlaying: Bool, progress: Double) {
        let state = NowPlayingActivityAttributes.ContentState(title: track.title, artist: track.artistName, isPlaying: isPlaying, progress: progress)
        Task { @MainActor in await self.applyUpdate(state: state) }
    }
    private func applyUpdate(state: NowPlayingActivityAttributes.ContentState) async {
        if let activity {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            activity = try? Activity.request(attributes: NowPlayingActivityAttributes(),
                                             content: ActivityContent(state: state, staleDate: nil))
        }
    }
    func end() {
        Task { @MainActor in await self.applyEnd() }
    }
    private func applyEnd() async {
        let current = activity
        activity = nil
        await current?.end(nil, dismissalPolicy: .immediate)
    }
}
