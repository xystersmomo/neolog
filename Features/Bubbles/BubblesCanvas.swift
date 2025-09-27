import SwiftUI

struct BubblesCanvas: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var physics = BubblePhysics()
    @State private var tooltip: Tooltip?

    struct Tooltip: Identifiable {
        let id = UUID()
        let activityName: String
        let colorHex: String
        let position: CGPoint
        let totalMinutes: Int
    }

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                physics.configure(bounds: size, activities: app.availableActivities, running: app.runningSession)
                for bubble in physics.bubbles {
                    guard let color = Color(hex: bubble.colorHex) else { continue }
                    var circle = Path(ellipseIn: CGRect(x: bubble.position.x - bubble.radius,
                                                        y: bubble.position.y - bubble.radius,
                                                        width: bubble.radius * 2,
                                                        height: bubble.radius * 2))
                    let isRunning = bubble.activityName.caseInsensitiveCompare(app.runningSession?.activityName ?? "") == .orderedSame
                    let alpha: Double = isRunning ? 0.85 : 0.45
                    context.fill(circle, with: .color(color.opacity(alpha)))
                }
            }
            .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                let point = value.location
                if let bubble = physics.bubbles.first(where: { bubble in
                    let dx = bubble.position.x - point.x
                    let dy = bubble.position.y - point.y
                    return sqrt(dx * dx + dy * dy) <= bubble.radius
                }) {
                    let totalSeconds = app.totalSeconds(for: bubble.activityName)
                    let minutes = max(1, Int(round(Double(totalSeconds) / 60.0)))
                    tooltip = Tooltip(activityName: bubble.activityName.isEmpty ? "미분류" : bubble.activityName,
                                      colorHex: bubble.colorHex,
                                      position: point,
                                      totalMinutes: minutes)
                } else {
                    tooltip = nil
                }
            })
            .onDisappear {
                physics.tearDown()
            }
            .overlay(alignment: .topLeading) {
                if let tooltip {
                    BubbleTooltip(tooltip: tooltip)
                        .position(tooltip.position)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
}

private struct BubbleTooltip: View {
    let tooltip: BubblesCanvas.Tooltip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tooltip.activityName)
                .font(.headline)
            Text("총 \(tooltip.totalMinutes)분")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: tooltip.colorHex) ?? .accentColor, lineWidth: 1)
        )
        .shadow(radius: 8)
    }
}
