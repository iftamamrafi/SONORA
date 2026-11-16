
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(PreferencesStore.self) private var preferences
    @Environment(PlaybackManager.self) private var playback
    @Environment(\.modelContext) private var context
    @State private var showClearHistoryConfirm = false
    @State private var cacheMessage: String?

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Appearance", selection: Binding(get: { preferences.appearance }, set: { preferences.appearance = $0 })) {
                    ForEach(AppearanceMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }
            }
            Section("Playback") {
                Toggle("Autoplay", isOn: Binding(get: { preferences.autoplayEnabled }, set: { preferences.autoplayEnabled = $0 }))
                Toggle("Shuffle by default", isOn: Binding(get: { preferences.defaultShuffle }, set: { preferences.defaultShuffle = $0 }))
                Picker("Default Repeat", selection: Binding(get: { preferences.defaultRepeatRaw }, set: { preferences.defaultRepeatRaw = $0; playback.queue.repeatMode = preferences.defaultRepeat })) {
                    ForEach(RepeatMode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0.rawValue) }
                }
                Picker("Playback Speed", selection: Binding(get: { preferences.playbackSpeed }, set: { preferences.playbackSpeed = $0; playback.playbackSpeed = $0 })) {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { Text(String(format: "%.2g×", $0)).tag($0) }
                }
                Toggle("Crossfade (where supported)", isOn: Binding(get: { preferences.crossfadeEnabled }, set: { preferences.crossfadeEnabled = $0 }))
                NavigationLink { EqualizerView() } label: { Label("Equalizer", systemImage: "slider.vertical.3") }
            }
            Section("Online Provider") {
                Toggle("Demo provider (SoundHelix test audio)", isOn: Binding(get: { preferences.providerEnabled }, set: { preferences.providerEnabled = $0; appState.refreshProvider() }))
                Text("Demo content is clearly labeled and streams test audio only. Add a licensed provider by implementing the MusicProvider protocol.")
                    .font(.caption).foregroundStyle(DS.textSecondary)
            }
            Section("Storage") {
                let usage = ArtworkCache.storageUsage()
                LabeledContent("Imported music", value: ByteCountFormatter.string(fromByteCount: usage.music, countStyle: .file))
                LabeledContent("Downloads", value: ByteCountFormatter.string(fromByteCount: usage.downloads, countStyle: .file))
                Button("Clear Artwork Cache") { ArtworkCache.clearArtworkFiles(); cacheMessage = "Artwork cache cleared." }
                if let cacheMessage { Text(cacheMessage).font(.caption).foregroundStyle(DS.textSecondary) }
            }
            Section("Privacy") {
                Button("Clear Listening History", role: .destructive) { showClearHistoryConfirm = true }
                Button("Clear Search History") { preferences.clearSearchHistory() }
                Text("SONORA collects nothing. Your music and listening data stay on this device.").font(.caption).foregroundStyle(DS.textSecondary)
            }
            Section("About") {
                LabeledContent("App", value: "SONORA")
                LabeledContent("Version", value: "1.0.0 (1)")
                LabeledContent("Tagline", value: "Your Music. Your World. Always in Rhythm.")
                Text("Built with SwiftUI, AVFoundation and SwiftData. Demo audio: SoundHelix test tracks.").font(.caption).foregroundStyle(DS.textSecondary)
            }
        }
        .scrollContentBackground(.hidden).sonoraBackground()
        .navigationTitle("Settings")
        .confirmationDialog("Clear all listening history?", isPresented: $showClearHistoryConfirm) {
            Button("Clear History", role: .destructive) {
                let history = (try? context.fetch(FetchDescriptor<ListeningHistoryEntity>())) ?? []
                history.forEach { context.delete($0) }
                let tracks = (try? context.fetch(FetchDescriptor<TrackEntity>())) ?? []
                tracks.forEach { $0.playCount = 0; $0.lastPlayedAt = nil }
                try? context.save()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
