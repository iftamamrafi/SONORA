
import Foundation
import ActivityKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}
    func update(track: TrackSnapshot, isPlaying: Bool, progress: Double) {
        let state = NowPlayingActivityAttributes.ContentState(title: track.title, artist: track.artistName, isPlaying: isPlaying, progress: progress)
        let content = ActivityContent(state: state, staleDate: nil)
        // The Activity is looked up inside the task so the (non-Sendable) Activity
        // value originates in the task's own region instead of being sent across
        // an isolation boundary, which Swift 6 region isolation forbids.
        Task {
            if let activity = Activity<NowPlayingActivityAttributes>.activities.first {
                await activity.update(content)
            } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                _ = try? Activity.request(attributes: NowPlayingActivityAttributes(), content: content)
            }
        }
    }
    func end() {
        Task {
            for activity in Activity<NowPlayingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
