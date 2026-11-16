
import WidgetKit
import SwiftUI
import ActivityKit

@main
struct SONORAWidgetsBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingLiveActivity()
    }
}

struct NowPlayingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title).font(.headline).lineLimit(1)
                    Text(context.state.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    ProgressView(value: context.state.progress).tint(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
                }
                Spacer()
            }
            .padding(14)
            .activityBackgroundTint(Color(red: 0x08/255, green: 0x08/255, blue: 0x0B/255))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "music.note").foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                        .foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.title).font(.headline).lineLimit(1)
                        Text(context.state.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress).tint(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
                }
            } compactLeading: {
                Image(systemName: "music.note").foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
            } minimal: {
                Image(systemName: "music.note").foregroundStyle(Color(red: 0xB6/255, green: 0x9C/255, blue: 1))
            }
        }
    }
}
