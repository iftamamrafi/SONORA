
import SwiftUI

struct EqualizerView: View {
    @Environment(AppState.self) private var appState
    @Environment(PlaybackManager.self) private var playback
    @Environment(PreferencesStore.self) private var preferences
    @Environment(\.dismiss) private var dismiss
    @State private var gains: [Double] = Array(repeating: 0, count: 10)

    private var currentIsStream: Bool {
        guard let t = playback.currentTrack else { return false }
        return !t.isLocalFile
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Toggle(isOn: Binding(get: { preferences.eqEnabled }, set: { preferences.eqEnabled = $0; appState.applyEQSettings() })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Equalizer").font(.headline).foregroundStyle(DS.textPrimary)
                        Text("Real 10-band AVAudioUnitEQ for local files").font(.caption).foregroundStyle(DS.textSecondary)
                    }
                }
                .tint(DS.accent).padding(16).cardStyle()

                if currentIsStream {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("The current track is an online stream. Streams play through AVPlayer, which cannot route through the EQ engine, so the equalizer does not affect this track. It applies automatically to local files.")
                            .font(.caption).foregroundStyle(DS.textSecondary)
                    }
                    .padding(14).cardStyle()
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Presets")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(EQPreset.all) { preset in
                                Button(preset.name) { applyPreset(preset) }
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(preferences.eqPresetName == preset.name ? DS.accent : DS.surface, in: Capsule())
                                    .foregroundStyle(preferences.eqPresetName == preset.name ? .black : DS.textPrimary)
                            }
                        }
                    }
                }

                VStack(spacing: 14) {
                    ForEach(0..<10, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text(label(for: i)).font(.caption).foregroundStyle(DS.textSecondary).frame(width: 44, alignment: .trailing).monospacedDigit()
                            Slider(value: $gains[i], in: -12...12, step: 0.5) { _ in commitCustom() }
                                .tint(DS.accent).disabled(!preferences.eqEnabled)
                            Text(String(format: "%+.0f dB", gains[i])).font(.caption).foregroundStyle(DS.textSecondary).frame(width: 46).monospacedDigit()
                        }
                    }
                }
                .padding(16).cardStyle()
                Text("Changes apply live to local playback through the EQ engine. Switching EQ on or off takes effect from the next local track you play.")
                    .font(.caption2).foregroundStyle(DS.textSecondary)
            }
            .padding(18)
        }
        .sonoraBackground()
        .navigationTitle("Equalizer")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        .onAppear { gains = appState.currentEQGains().map { Double($0) } }
    }
    private func label(for i: Int) -> String {
        let f = EQPreset.frequencies[i]
        return f >= 1000 ? "\(Int(f / 1000))k" : "\(Int(f))"
    }
    private func applyPreset(_ preset: EQPreset) {
        preferences.eqPresetName = preset.name
        gains = preset.gains.map { Double($0) }
        appState.applyEQSettings()
    }
    private func commitCustom() {
        preferences.eqPresetName = "Custom"
        preferences.eqCustomGains = gains
        appState.applyEQSettings()
    }
}
