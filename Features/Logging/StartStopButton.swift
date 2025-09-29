import SwiftUI

struct StartStopButton: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.colorScheme) private var colorScheme

    private enum FeedbackStyle {
        case light
        case medium
    }

    private var isRunning: Bool {
        if case .running = app.state { return true }
        return false
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRunning ? Color.red.opacity(0.85) : Color.accentColor)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.4 : 0.2), lineWidth: 6)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
                Text(isRunning ? "Stop" : "Start")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .accessibilityLabel(isRunning ? "Stop logging" : "Start logging")
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isRunning ? 0.95 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRunning)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.2).onEnded { _ in
            provideHaptic(style: .light)
        })
    }

    private func action() {
        provideHaptic(style: .medium)
        if isRunning {
            app.stopLogging()
        } else {
            let lastActivity = app.availableActivities.sortedByRecent().first
            app.startLogging(activityName: lastActivity?.name)
        }
    }

    private func provideHaptic(style: FeedbackStyle) {
        #if canImport(UIKit)
        let generatorStyle: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch style {
            case .light: return .light
            case .medium: return .medium
            }
        }()
        UIImpactFeedbackGenerator(style: generatorStyle).impactOccurred()
        #endif
    }
}

struct StartStopButton_Previews: PreviewProvider {
    static var previews: some View {
        StartStopButton()
            .environmentObject(AppState(store: Store()))
            .frame(width: 200, height: 200)
    }
}
