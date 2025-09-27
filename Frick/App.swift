import SwiftUI

@main
struct FrickApp: App {
    @StateObject private var appBlocker = AppBlocker()
    @StateObject private var profileManager = ProfileManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appBlocker)
                .environmentObject(profileManager)
        }
    }
}
