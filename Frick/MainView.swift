import SwiftUI
import CoreNFC
import FamilyControls
import ManagedSettings
import os.log

private extension Logger {
    static let main = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.frick", category: "MainView")
}

struct MainView: View {
    @EnvironmentObject private var appBlocker: AppBlocker
    @EnvironmentObject private var profileManager: ProfileManager
    @StateObject private var nfcReader = NFCReader()
    private let tagPhrase = "FRICK!!"

    @State private var showWrongTagAlert = false
    @State private var showCreateTagAlert = false
    @State private var nfcWriteSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var elapsedTime: TimeInterval = 0
    @State private var showAddProfile = false
    @State private var editingProfile: Profile?
    @State private var dailyBlockedTime: TimeInterval = 0
    @State private var sessionStartTime: Date?
    @State private var showProfileManager = false

    private var isBlocking: Bool {
        appBlocker.isBlocking
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Sleek dark gray background
                Theme.backgroundColor
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Status text above button
                        Text(isBlocking ? "TAP TO UNLOCK" : "TAP TO BLOCK")
                            .font(.system(size: 18, weight: .medium, design: .default))
                            .foregroundColor(Theme.secondaryTextColor)
                            .tracking(2)
                            .padding(.bottom, 40)

                        // Central square button - like Brick app
                        SquareButton(isBlocking: isBlocking) {
                            scanTag()
                        }

                        // Profile selector
                        profileSection
                            .padding(.top, 30)
                    }

                    Spacer()

                    // Daily time tracker - always visible
                    DailyTimeTracker(
                        isBlocking: isBlocking,
                        dailyBlockedTime: $dailyBlockedTime,
                        elapsedTime: $elapsedTime,
                        sessionStartTime: $sessionStartTime
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FRICK")
                        .font(.system(size: 22, weight: .regular, design: .monospaced))
                        .foregroundColor(Theme.primaryTextColor)
                        .tracking(1)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showCreateTagAlert = true
                            HapticManager.impact(.light)
                        }) {
                            Label("Create NFC Tag", systemImage: "plus.circle")
                        }

                        Button(action: {
                            showProfileManager = true
                            HapticManager.impact(.light)
                        }) {
                            Label("Manage Profiles", systemImage: "person.2")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(Theme.primaryTextColor)
                    }
                }
            }
            .animation(Theme.animation, value: isBlocking)
            .onAppear {
                loadBlockState()
            }
            .alert(isPresented: $showWrongTagAlert) {
                Alert(
                    title: Text("Invalid Tag"),
                    message: Text("This is not a Frick tag. Create a new tag using the menu."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Create Frick Tag", isPresented: $showCreateTagAlert) {
                Button("Create") { createBrokerTag() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Hold your phone near an NFC tag to program it.")
            }
            .alert("Tag Status", isPresented: $nfcWriteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(nfcWriteSuccess ? "Tag created successfully!" : "Failed to create tag. Please try again.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showAddProfile) {
                ProfileFormView(profileManager: profileManager) {
                    showAddProfile = false
                }
            }
            .sheet(item: $editingProfile) { profile in
                ProfileFormView(profile: profile, profileManager: profileManager) {
                    editingProfile = nil
                }
            }
            .background(
                NavigationLink(
                    destination: ProfileListView(profileManager: profileManager),
                    isActive: $showProfileManager,
                    label: { EmptyView() }
                )
            )
        }
    }

    private var profileSection: some View {
        Menu {
            ForEach(profileManager.profiles) { profile in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(Theme.animation) {
                        profileManager.setCurrentProfile(id: profile.id)
                    }
                }) {
                    HStack {
                        Text("\(profile.icon) \(profile.name)")
                        if profile.id == profileManager.currentProfileId {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button(action: {
                HapticManager.impact(.light)
                showAddProfile = true
            }) {
                Label("Add Profile", systemImage: "plus.circle")
            }

            Button(action: {
                HapticManager.impact(.light)
                if let currentProfile = profileManager.profiles.first(where: { $0.id == profileManager.currentProfileId }) {
                    editingProfile = currentProfile
                }
            }) {
                Label("Edit Current", systemImage: "pencil")
            }
        } label: {
            HStack(spacing: 6) {
                Text(profileManager.currentProfile.icon)
                    .font(.system(size: 16))

                Text(profileManager.currentProfile.name.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.secondaryTextColor)
                    .tracking(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.surfaceColor)
                    .overlay(
                        Capsule()
                            .stroke(Theme.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    private func loadBlockState() {
        // Load daily total first
        loadDailyTotal()

        if isBlocking {
            // Load saved session start time
            if let savedStartTime = UserDefaults.standard.object(forKey: "sessionStartTime") as? Date {
                sessionStartTime = savedStartTime
                elapsedTime = Date().timeIntervalSince(savedStartTime)
            } else {
                sessionStartTime = Date()
                UserDefaults.standard.set(sessionStartTime, forKey: "sessionStartTime")
            }
        } else {
            sessionStartTime = nil
            elapsedTime = 0
            UserDefaults.standard.removeObject(forKey: "sessionStartTime")
        }
    }

    private func loadDailyTotal() {
        let key = TimeFormatter.dailyBlockedTimeKey()
        let savedDaily = UserDefaults.standard.double(forKey: key)

        if isBlocking, let startTime = sessionStartTime {
            // Add current session to saved daily total
            dailyBlockedTime = savedDaily + Date().timeIntervalSince(startTime)
        } else {
            dailyBlockedTime = savedDaily
        }
    }

    private func scanTag() {
        guard NFCNDEFReaderSession.readingAvailable else {
            errorMessage = "NFC is not available on this device"
            showError = true
            return
        }

        nfcReader.scan { payload in
            if payload == tagPhrase {
                Logger.main.info("Toggling block")
                HapticManager.notification(.success)
                appBlocker.toggleBlocking(for: profileManager.currentProfile)

                // Update time tracking
                if appBlocker.isBlocking {
                    // Starting new session
                    sessionStartTime = Date()
                    UserDefaults.standard.set(sessionStartTime, forKey: "sessionStartTime")
                    elapsedTime = 0
                } else {
                    // Ending session - save to daily total
                    if let startTime = sessionStartTime {
                        let sessionDuration = Date().timeIntervalSince(startTime)
                        let key = TimeFormatter.dailyBlockedTimeKey()
                        let currentDaily = UserDefaults.standard.double(forKey: key)
                        UserDefaults.standard.set(currentDaily + sessionDuration, forKey: key)
                        dailyBlockedTime = currentDaily + sessionDuration
                    }

                    sessionStartTime = nil
                    elapsedTime = 0
                    UserDefaults.standard.removeObject(forKey: "sessionStartTime")
                }

                if let error = appBlocker.errorMessage {
                    HapticManager.notification(.error)
                    errorMessage = error
                    showError = true
                }
            } else {
                HapticManager.notification(.warning)
                showWrongTagAlert = true
                Logger.main.warning("Wrong Tag! Payload: \(payload)")
            }
        }
    }

    private func createBrokerTag() {
        nfcReader.write(tagPhrase) { success in
            nfcWriteSuccess = success
            showCreateTagAlert = false
        }
    }
}
