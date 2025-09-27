import SwiftUI

struct SquareButton: View {
    let isBlocking: Bool
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            withAnimation(Theme.springAnimation) {
                action()
            }
        }) {
            ZStack {
                // White shadow glow effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 210, height: 210)
                    .blur(radius: 10)

                // Square button background with thick outline
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.buttonColor)
                    .frame(width: 200, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color.white.opacity(0.1), radius: 8, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                isBlocking ?
                                Theme.blockingColor.opacity(0.6) :
                                Theme.accentColor.opacity(0.4),
                                lineWidth: 1
                            )
                            .padding(1)
                    )

                VStack(spacing: 12) {
                    // Status icon
                    Image(systemName: isBlocking ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 48, weight: .regular))
                        .foregroundColor(isBlocking ? Theme.blockingColor : Theme.primaryTextColor)

                    // Text on button
                    Text("FRICK")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(Theme.primaryTextColor)
                        .tracking(2)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.springAnimation, value: isPressed)
        .onLongPressGesture(
            minimumDuration: .infinity,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}