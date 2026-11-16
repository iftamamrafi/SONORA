
import Foundation
import ActivityKit

/// Shared between the SONORA app target and the SONORAWidgets extension target.
struct NowPlayingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var artist: String
        var isPlaying: Bool
        var progress: Double   // 0...1
    }
    var appName: String = "SONORA"
}
