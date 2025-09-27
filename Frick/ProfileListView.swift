import SwiftUI
import FamilyControls

struct ProfileListView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showAddProfile = false
    @State private var editingProfile: Profile?
    @State private var showDeleteAlert = false
    @State private var profileToDelete: Profile?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()

            if profileManager.profiles.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.secondaryTextColor.opacity(0.5))

                    Text("No Profiles")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.primaryTextColor)

                    Text("Create profiles to manage different blocking configurations")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: { showAddProfile = true }) {
                        Text("Create First Profile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Theme.accentColor)
                            .cornerRadius(20)
                    }
                    .padding(.top, 10)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // All profiles in one section, with current profile first
                        VStack(spacing: 12) {
                            // Current profile first
                            if let currentProfile = profileManager.profiles.first(where: { $0.id == profileManager.currentProfileId }) {
                                profileCard(for: currentProfile, isCurrent: true)
                            }

                            // Then other profiles
                            ForEach(profileManager.profiles.filter { $0.id != profileManager.currentProfileId }) { profile in
                                profileCard(for: profile, isCurrent: false)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
        }
        .navigationTitle("Manage Profiles")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !profileManager.profiles.isEmpty {
                    Button(action: { showAddProfile = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.primaryTextColor)
                    }
                }
            }
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
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Profile"),
                message: Text("Are you sure you want to delete \"\(profileToDelete?.name ?? "")\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let profile = profileToDelete {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            profileManager.deleteProfile(withId: profile.id)
                        }
                        HapticManager.notification(.success)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func profileCard(for profile: Profile, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            // Profile icon with background
            ZStack {
                Circle()
                    .fill(isCurrent ? Theme.accentColor.opacity(0.15) : Theme.surfaceColor)
                    .frame(width: 56, height: 56)

                Text(profile.icon)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.primaryTextColor)

                    if isCurrent {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.nonBlockingColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Theme.nonBlockingColor.opacity(0.15))
                            )
                    }
                }

                HStack(spacing: 12) {
                    Label("\(profile.appTokens.count)", systemImage: "app.badge")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryTextColor)

                    Label("\(profile.categoryTokens.count)", systemImage: "folder")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryTextColor)
                }
            }

            Spacer()

            // Action menu only
            Menu {
                Button(action: {
                    editingProfile = profile
                }) {
                    Label("Edit", systemImage: "pencil")
                }

                if !isCurrent && profileManager.profiles.count > 1 {
                    Divider()

                    Button(role: .destructive, action: {
                        profileToDelete = profile
                        showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.secondaryTextColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrent ?
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: isCurrent ? 2 : 0
                        )
                )
        )
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCurrent {
                withAnimation(.easeInOut(duration: 0.2)) {
                    profileManager.setCurrentProfile(id: profile.id)
                }
                HapticManager.impact(.light)
            }
        }
    }
}