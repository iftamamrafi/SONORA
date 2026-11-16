
import Foundation
import SwiftUI

@MainActor
@Observable
final class PreferencesStore {
    var appearance: AppearanceMode = .dark { didSet { save() } }
    var autoplayEnabled: Bool = true { didSet { save() } }
    var defaultShuffle: Bool = false { didSet { save() } }
    var defaultRepeatRaw: String = RepeatMode.off.rawValue { didSet { save() } }
    var playbackSpeed: Double = 1.0 { didSet { save() } }
    var crossfadeEnabled: Bool = false { didSet { save() } }
    var eqEnabled: Bool = false { didSet { save() } }
    var eqPresetName: String = "Normal" { didSet { save() } }
    var eqCustomGains: [Double] = Array(repeating: 0, count: 10) { didSet { save() } }
    var searchHistory: [String] = [] { didSet { save() } }
    var providerEnabled: Bool = true { didSet { save() } }

    private let defaults: UserDefaults
    private var isLoading = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isLoading = true
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .dark
        autoplayEnabled = defaults.object(forKey: "autoplay") as? Bool ?? true
        defaultShuffle = defaults.bool(forKey: "defaultShuffle")
        defaultRepeatRaw = defaults.string(forKey: "defaultRepeat") ?? RepeatMode.off.rawValue
        playbackSpeed = defaults.object(forKey: "speed") as? Double ?? 1.0
        crossfadeEnabled = defaults.bool(forKey: "crossfade")
        eqEnabled = defaults.bool(forKey: "eqEnabled")
        eqPresetName = defaults.string(forKey: "eqPreset") ?? "Normal"
        if let g = defaults.array(forKey: "eqGains") as? [Double], g.count == 10 { eqCustomGains = g }
        searchHistory = defaults.stringArray(forKey: "searchHistory") ?? []
        providerEnabled = defaults.object(forKey: "providerEnabled") as? Bool ?? true
        isLoading = false
    }
    var defaultRepeat: RepeatMode { RepeatMode(rawValue: defaultRepeatRaw) ?? .off }
    var colorScheme: ColorScheme? {
        switch appearance { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
    func addSearchTerm(_ term: String) {
        let t = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        searchHistory.removeAll { $0.lowercased() == t.lowercased() }
        searchHistory.insert(t, at: 0)
        searchHistory = Array(searchHistory.prefix(20))
    }
    func clearSearchHistory() { searchHistory = [] }
    private func save() {
        guard !isLoading else { return }
        defaults.set(appearance.rawValue, forKey: "appearance")
        defaults.set(autoplayEnabled, forKey: "autoplay")
        defaults.set(defaultShuffle, forKey: "defaultShuffle")
        defaults.set(defaultRepeatRaw, forKey: "defaultRepeat")
        defaults.set(playbackSpeed, forKey: "speed")
        defaults.set(crossfadeEnabled, forKey: "crossfade")
        defaults.set(eqEnabled, forKey: "eqEnabled")
        defaults.set(eqPresetName, forKey: "eqPreset")
        defaults.set(eqCustomGains, forKey: "eqGains")
        defaults.set(searchHistory, forKey: "searchHistory")
        defaults.set(providerEnabled, forKey: "providerEnabled")
    }
}
