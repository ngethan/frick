import SwiftUI
import ManagedSettings
import FamilyControls
import os.log

private extension Logger {
    static let appBlocker = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.frick", category: "AppBlocker")
}

class AppBlocker: ObservableObject {
    let store = ManagedSettingsStore()
    @Published var isBlocking = false
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    init() {
        loadBlockingState()
        Task {
            await requestAuthorization()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        } catch {
            Logger.appBlocker.error("Failed to request authorization: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.errorMessage = "Screen Time permission required. Please enable it in Settings."
            }
        }
    }
    
    func toggleBlocking(for profile: Profile) {
        guard isAuthorized else {
            Logger.appBlocker.warning("Not authorized to block apps")
            return
        }
        
        isBlocking.toggle()
        saveBlockingState()
        applyBlockingSettings(for: profile)
    }
    
    func applyBlockingSettings(for profile: Profile) {
        do {
            if isBlocking {
                Logger.appBlocker.info("Blocking \(profile.appTokens.count) apps and \(profile.categoryTokens.count) categories")
                store.shield.applications = profile.appTokens.isEmpty ? nil : profile.appTokens
                store.shield.applicationCategories = profile.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none : .specific(profile.categoryTokens)
            } else {
                Logger.appBlocker.info("Unblocking all apps")
                store.shield.applications = nil
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
            }
            errorMessage = nil
        } catch {
            Logger.appBlocker.error("Failed to apply blocking settings: \(error.localizedDescription)")
            errorMessage = "Failed to apply settings. Please try again."
        }
    }
    
    private func loadBlockingState() {
        isBlocking = UserDefaults.standard.bool(forKey: "isBlocking")
    }
    
    private func saveBlockingState() {
        UserDefaults.standard.set(isBlocking, forKey: "isBlocking")
    }
}