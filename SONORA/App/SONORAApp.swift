
import SwiftUI
import SwiftData

@main
struct SONORAApp: App {
    @State private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appState.playback)
                .environment(appState.preferences)
                .environment(appState.network)
                .environment(appState.downloads)
                .preferredColorScheme(appState.preferences.colorScheme)
        }
        .modelContainer(appState.container)
    }
}
