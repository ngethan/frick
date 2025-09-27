import SwiftUI

struct Theme {
    // Sleek dark gray palette
    static let backgroundColor = Color(red: 0.11, green: 0.11, blue: 0.12) // Dark gray background
    static let surfaceColor = Color(red: 0.15, green: 0.15, blue: 0.16) // Slightly lighter for cards
    static let buttonColor = Color(red: 0.22, green: 0.22, blue: 0.24) // Button surface
    static let primaryTextColor = Color.white
    static let secondaryTextColor = Color(red: 0.6, green: 0.6, blue: 0.63)

    // Accent colors
    static let accentColor = Color(red: 0.3, green: 0.3, blue: 0.32)
    static let blockingColor = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let nonBlockingColor = Color(red: 0.3, green: 0.8, blue: 0.5)

    // Clean, modern spacing
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 0 // No shadows for ultra-clean look
    static let spacing: CGFloat = 24
    static let compactSpacing: CGFloat = 12
    static let padding: CGFloat = 20

    // Smooth animations
    static let animation = Animation.easeInOut(duration: 0.25)
    static let springAnimation = Animation.spring(response: 0.35, dampingFraction: 0.85)

    // Typography
    static let titleFont = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .medium, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 13, weight: .regular, design: .rounded)
}

extension View {
    func minimalCard() -> some View {
        self
            .background(Theme.surfaceColor)
            .cornerRadius(Theme.cornerRadius)
    }

    func subtleCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
    }

    func glassCard() -> some View {
        self
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
            )
    }

    func primaryButton() -> some View {
        self
            .font(Theme.bodyFont)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Theme.primaryTextColor)
            .cornerRadius(Theme.cornerRadius)
    }

    func secondaryButton() -> some View {
        self
            .font(Theme.bodyFont)
            .foregroundColor(Theme.primaryTextColor)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.primaryTextColor, lineWidth: 1.5)
            )
    }
}