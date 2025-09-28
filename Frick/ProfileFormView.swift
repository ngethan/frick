import SwiftUI
import FamilyControls
import ManagedSettings
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

                appsSection
                categoriesSection

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

    @ViewBuilder
    private var appsSection: some View {
        if activitySelection.applicationTokens.count > 0 || activitySelection.categoryTokens.count == 0 {
            Section {
                appsContent
            } header: {
                appsHeader
            }
        }
    }

    @ViewBuilder
    private var appsContent: some View {
        if activitySelection.applicationTokens.isEmpty {
            HStack {
                Text("No apps selected")
                    .foregroundColor(Theme.secondaryTextColor)
                Spacer()
                Button("Add Apps") {
                    showAppSelection = true
                    HapticManager.impact(.light)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.accentColor)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(activitySelection.applicationTokens).prefix(8), id: \.self) { token in
                    appRow(for: token)
                }

                if activitySelection.applicationTokens.count > 8 {
                    Text("... and \(activitySelection.applicationTokens.count - 8) more")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryTextColor)
                        .padding(.leading, 32)
                }
            }
        }
    }

    private var appsHeader: some View {
        HStack {
            Text("Blocked Apps")
                .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
            Spacer()
            Button("Edit") {
                showAppSelection = true
                HapticManager.impact(.light)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Theme.accentColor)
        }
    }

    @ViewBuilder
    private func appRow(for token: ApplicationToken) -> some View {
        HStack {
            Label(token)
                .foregroundColor(Theme.primaryTextColor)
            Spacer()
        }
    }

    @ViewBuilder
    private var categoriesSection: some View {
        if activitySelection.categoryTokens.count > 0 || activitySelection.applicationTokens.count == 0 {
            Section {
                categoriesContent
            } header: {
                categoriesHeader
            }
        }
    }

    @ViewBuilder
    private var categoriesContent: some View {
        if activitySelection.categoryTokens.isEmpty {
            HStack {
                Text("No categories selected")
                    .foregroundColor(Theme.secondaryTextColor)
                Spacer()
                Button("Add Categories") {
                    showAppSelection = true
                    HapticManager.impact(.light)
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.accentColor)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(activitySelection.categoryTokens), id: \.self) { token in
                    categoryRow(for: token)
                }
            }
        }
    }

    private var categoriesHeader: some View {
        HStack {
            Text("Blocked Categories")
                .foregroundColor(Theme.secondaryTextColor.opacity(0.8))
            Spacer()
            Button("Edit") {
                showAppSelection = true
                HapticManager.impact(.light)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Theme.accentColor)
        }
    }

    @ViewBuilder
    private func categoryRow(for token: ActivityCategoryToken) -> some View {
        HStack {
            Label(token)
                .foregroundColor(Theme.primaryTextColor)
            Spacer()
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

