# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Frick is an iOS app that helps users focus by blocking distracting apps through NFC tag interactions. Built with SwiftUI and requires iOS 16.4+ for Family Controls API integration.

## Build & Development Commands

### Building the Application
```bash
# Build for debug (simulator or device)
xcodebuild -scheme Frick -configuration Debug build

# Build for release
xcodebuild -scheme Frick -configuration Release build

# Clean build folder
xcodebuild -scheme Frick clean

# Run on connected device
xcodebuild -scheme Frick -destination 'platform=iOS,name=[device name]' build
```

### Running the App
- Open `Frick.xcodeproj` in Xcode
- Select target device (requires physical iPhone for NFC testing)
- Press Cmd+R or click Run button
- Note: NFC features require physical device (iPhone 7+)

## Architecture & Core Components

### State Management
The app uses SwiftUI's `@StateObject` and `@EnvironmentObject` pattern with two main managers:

**AppBlocker** (`AppBlocker.swift`): Manages Screen Time blocking functionality
- Handles Family Controls authorization
- Toggles app blocking state via ManagedSettingsStore
- Persists blocking state in UserDefaults
- Applies shield settings to block/unblock apps

**ProfileManager** (`ProfileManager.swift`): Manages blocking profiles
- Stores multiple profiles with different app/category combinations
- Each profile contains: name, icon, app tokens, category tokens
- Persists profiles to UserDefaults as JSON
- Maintains current active profile

### NFC Integration
**NFCReader** (`NfcReader.swift`): Handles all NFC tag operations
- Dual-mode operation: reading and writing
- Uses NFCNDEFReaderSession for tag detection
- Writes profile identifiers to tags
- Reads tags to trigger blocking/unblocking

### Required Entitlements
The app requires these entitlements (`Frick.entitlements`):
- `com.apple.developer.family-controls`: For Screen Time API access
- `com.apple.developer.nfc.readersession.formats`: For NFC tag reading

### Key Dependencies
- **FamilyControls**: Apple framework for parental controls and app restrictions
- **ManagedSettings**: Framework for applying Screen Time settings
- **CoreNFC**: Framework for Near Field Communication tag operations
- No external package managers (CocoaPods/SPM/Carthage) - uses only Apple frameworks

## Development Considerations

### Testing NFC Features
- Must use physical iPhone device (iPhone 7 or newer)
- Simulator does not support NFC functionality
- Use NTAG213 NFC tags for best compatibility

### Screen Time Permissions
- App requires user to grant Screen Time permissions on first launch
- Authorization handled through `AuthorizationCenter.shared.requestAuthorization()`
- Check `isAuthorized` state before attempting to block apps