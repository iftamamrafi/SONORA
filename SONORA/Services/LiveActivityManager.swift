
import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<NowPlayingActivityAttributes>?
    private init() {}
    func update(track: TrackSnapshot, isPlaying: Bool, progress: Double) {
        let state = NowPlayingActivityAttributes.ContentState(title: track.title, artist: track.artistName, isPlaying: isPlaying, progress: progress)
        if let activity {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
        } else {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            activity = try? Activity.request(attributes: NowPlayingActivityAttributes(),
                                             content: ActivityContent(state: state, staleDate: nil))
        }
    }
    func end() {
        let current = activity
        activity = nil
        Task { await current?.end(nil, dismissalPolicy: .immediate) }
    }
}
