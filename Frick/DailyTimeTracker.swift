import SwiftUI

struct DailyTimeTracker: View {
    let isBlocking: Bool
    @Binding var dailyBlockedTime: TimeInterval
    @Binding var elapsedTime: TimeInterval
    @Binding var sessionStartTime: Date?

    var body: some View {
        VStack(spacing: 16) {
            // Progress bar showing daily progress
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.surfaceColor)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    isBlocking ? Theme.blockingColor : Theme.nonBlockingColor.opacity(0.6),
                                    isBlocking ? Theme.blockingColor.opacity(0.7) : Theme.nonBlockingColor.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(geometry.size.width * (dailyBlockedTime / (4 * 3600)), geometry.size.width), height: 4)
                        .animation(.easeInOut(duration: 0.3), value: dailyBlockedTime)
                }
            }
            .frame(height: 4)

            // Time display
            HStack(alignment: .bottom, spacing: 0) {
                // Daily total
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
                        .tracking(1.2)

                    Text(TimeFormatter.formatTime(dailyBlockedTime))
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.primaryTextColor)
                }

                Spacer()

                // Current session (if active)
                if isBlocking {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.blockingColor)
                                .frame(width: 6, height: 6)
                                .overlay(
                                    Circle()
                                        .fill(Theme.blockingColor)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.5)
                                        .scaleEffect(2)
                                        .opacity(isBlocking ? 1 : 0)
                                        .animation(
                                            Animation.easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: true),
                                            value: isBlocking
                                        )
                                )

                            Text("SESSION")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.blockingColor.opacity(0.8))
                                .tracking(1.2)
                        }

                        Text(TimeFormatter.formatTime(elapsedTime))
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.blockingColor)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }

                // Goal indicator
                if !isBlocking {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("GOAL")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.6))
                            .tracking(1.2)

                        Text("4H")
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.secondaryTextColor.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.surfaceColor.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.accentColor.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateElapsedTime()
        }
    }

    private func updateElapsedTime() {
        // Update current session time
        if isBlocking, let startTime = sessionStartTime {
            elapsedTime = Date().timeIntervalSince(startTime)
        }

        // Load daily total
        loadDailyTotal()
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
}