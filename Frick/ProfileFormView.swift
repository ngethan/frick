import SwiftUI
import FamilyControls
import MCEmojiPicker

struct ProfileFormView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var profileName: String
    @State private var profileEmoji: String
    @State private var showEmojiPicker = false
    @State private var showAppSelection = false
    @State private var activitySelection: FamilyActivitySelection
    @State private var showDeleteConfirmation = false
    let profile: Profile?
    let onDismiss: () -> Void

    init(profile: Profile? = nil, profileManager: ProfileManager, onDismiss: @escaping () -> Void) {
        self.profile = profile
        self.profileManager = profileManager
        self.onDismiss = onDismiss
        _profileName = State(initialValue: profile?.name ?? "")
        _profileEmoji = State(initialValue: profile?.icon ?? "🔕")

        var selection = FamilyActivitySelection()
        selection.applicationTokens = profile?.appTokens ?? []
        selection.categoryTokens = profile?.categoryTokens ?? []
        _activitySelection = State(initialValue: selection)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Name Field
                    HStack {
                        Text("Name")
                            .foregroundColor(Theme.primaryTextColor)
                        Spacer()
                        TextField("Required", text: $profileName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Theme.secondaryTextColor)
                    }

                    // Emoji Picker
                    HStack {
                        Text("Icon")
                            .foregroundColor(Theme.primaryTextColor)
                        Spacer()
                        Text(profileEmoji)
                            .font(.system(size: 24))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.5))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showEmojiPicker = true
                        HapticManager.impact(.light)
                    }
                } header: {
                    Text("Profile Details")
                        .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
                }

                Section {
                    Button(action: {
                        showAppSelection = true
                        HapticManager.impact(.light)
                    }) {
                        HStack {
                            Label("Apps & Categories", systemImage: "app.badge")
                                .foregroundColor(Theme.primaryTextColor)
                            Spacer()
                            HStack(spacing: 4) {
                                if activitySelection.applicationTokens.count > 0 {
                                    Text("\(activitySelection.applicationTokens.count)")
                                        .foregroundColor(Theme.secondaryTextColor)
                                }
                                if activitySelection.categoryTokens.count > 0 {
                                    Text("+\(activitySelection.categoryTokens.count)")
                                        .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.secondaryTextColor.opacity(0.5))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Blocking Configuration")
                        .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
                } footer: {
                    if activitySelection.applicationTokens.count == 0 && activitySelection.categoryTokens.count == 0 {
                        Text("No apps or categories selected")
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
                    } else {
                        Text("\(activitySelection.applicationTokens.count) apps, \(activitySelection.categoryTokens.count) categories")
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
                    }
                }

                // Delete Button (if editing)
                if profile != nil {
                    Section {
                        Button(action: {
                            showDeleteConfirmation = true
                            HapticManager.impact(.light)
                        }) {
                            HStack {
                                Spacer()
                                Text("Delete Profile")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel", action: onDismiss)
                    .foregroundColor(Theme.primaryTextColor),
                trailing: Button(action: handleSave) {
                    Text("Save")
                        .fontWeight(.medium)
                        .foregroundColor(canSave() ? Theme.primaryTextColor : Theme.secondaryTextColor)
                }
                .disabled(!canSave())
            )
            .sheet(isPresented: $showAppSelection) {
                NavigationView {
                    FamilyActivityPicker(selection: $activitySelection)
                        .navigationTitle("Select Apps")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showAppSelection = false
                            }
                            .foregroundColor(Theme.primaryTextColor)
                        )
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Profile"),
                    message: Text("This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let profile = profile {
                            profileManager.deleteProfile(withId: profile.id)
                        }
                        onDismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $showEmojiPicker) {
                EmojiPickerWrapper(selectedEmoji: $profileEmoji) {
                    showEmojiPicker = false
                }
                .ignoresSafeArea()
            }
        }
    }

    private func canSave() -> Bool {
        let nameIsValid = !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if let existingProfile = profile {
            // For editing: check if anything changed
            return nameIsValid && (
                profileName != existingProfile.name ||
                profileEmoji != existingProfile.icon ||
                activitySelection.applicationTokens != existingProfile.appTokens ||
                activitySelection.categoryTokens != existingProfile.categoryTokens
            )
        } else {
            // For new profile: just need valid name
            return nameIsValid
        }
    }

    private func handleSave() {
        if let existingProfile = profile {
            profileManager.updateProfile(
                id: existingProfile.id,
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                icon: profileEmoji
            )
        } else {
            let newProfile = Profile(
                name: profileName,
                appTokens: activitySelection.applicationTokens,
                categoryTokens: activitySelection.categoryTokens,
                icon: profileEmoji
            )
            profileManager.addProfile(newProfile: newProfile)
        }
        onDismiss()
    }
}

// UIViewControllerRepresentable wrapper for MCEmojiPickerViewController
struct EmojiPickerWrapper: UIViewControllerRepresentable {
    @Binding var selectedEmoji: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = MCEmojiPickerViewController()
        picker.delegate = context.coordinator
        picker.sourceView = UIView() // Required for iPad

        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.navigationBar.topItem?.title = "Choose Icon"

        // Add Done button
        navigationController.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.dismissPicker)
        )

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MCEmojiPickerDelegate {
        let parent: EmojiPickerWrapper

        init(_ parent: EmojiPickerWrapper) {
            self.parent = parent
        }

        func didGetEmoji(emoji: String) {
            // Update the emoji first
            DispatchQueue.main.async {
                self.parent.selectedEmoji = emoji
            }
            // Don't auto-dismiss - let user tap Done button
        }

        @objc func dismissPicker() {
            parent.onDismiss()
        }
    }
}

