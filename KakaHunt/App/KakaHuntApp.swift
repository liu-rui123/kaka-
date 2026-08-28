import SwiftUI

@main
struct KakaHuntApp: App {
    @StateObject private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(settingsStore)
        }
    }
}

