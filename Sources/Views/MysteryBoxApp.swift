import SwiftUI

@main
struct MysteryBoxApp: App {
    @StateObject private var store = DataStore.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
