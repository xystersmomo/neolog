import Foundation
import SwiftUI
import QuartzCore

struct Bubble: Identifiable, Codable {
    var id: UUID
    var activityName: String
    var colorHex: String
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat

    init(id: UUID = UUID(), activityName: String, colorHex: String, position: CGPoint, velocity: CGVector, radius: CGFloat) {
        self.id = id
        self.activityName = activityName
        self.colorHex = colorHex
        self.position = position
        self.velocity = velocity
        self.radius = radius
    }
}

final class BubblePhysics: ObservableObject {
    @Published var bubbles: [Bubble] = []
    private var displayLink: CADisplayLink?
    private var bounds: CGSize = .zero
    private var weightedActivities: [(activity: Activity, cumulativeWeight: Double)] = []
    private var totalWeight: Double = 0

    func configure(bounds: CGSize, activities: [Activity], running: Session?) {
        self.bounds = bounds
        var pool = activities
        if let running, !running.activityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           pool.first(where: { $0.name.caseInsensitiveCompare(running.activityName) == .orderedSame }) == nil {
            let hex = colorHex(for: running.activityName)
            let activity = Activity(name: running.activityName, colorHex: hex, totalSeconds: running.durationSeconds)
            pool.append(activity)
        }
        guard !pool.isEmpty else {
            bubbles.removeAll()
            weightedActivities = []
            totalWeight = 0
            return
        }
        rebuildWeights(using: pool, running: running)

        bubbles = bubbles.filter { bubble in
            pool.contains { $0.name.caseInsensitiveCompare(bubble.activityName) == .orderedSame }
        }

        let baselineCount = pool.count * 8
        let historyMinutes = max(totalWeight / 60.0, 1)
        let densityCount = Int(sqrt(historyMinutes)) * 6
        let targetCount = min(120, max(20, max(baselineCount, densityCount)))
        if bubbles.count < targetCount {
            let diff = targetCount - bubbles.count
            let newBubbles = (0..<diff).compactMap { _ -> Bubble? in
                guard let activity = pickWeightedActivity(fallbackPool: pool) else { return nil }
                return makeBubble(for: activity)
            }
            bubbles.append(contentsOf: newBubbles)
        } else if bubbles.count > targetCount {
            bubbles = Array(bubbles.prefix(targetCount))
        }

        if let running,
           let activity = pool.first(where: { $0.name.caseInsensitiveCompare(running.activityName) == .orderedSame }) {
            bubbles.enumerated().forEach { idx, bubble in
                if bubble.activityName.caseInsensitiveCompare(activity.name) == .orderedSame {
                    bubbles[idx].radius = max(bubble.radius, 24)
                } else {
                    bubbles[idx].radius = max(14, bubble.radius * 0.95)
                }
            }
        }

        if displayLink == nil {
            let link = CADisplayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }
    }

    func tearDown() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func step(link: CADisplayLink) {
        let delta = max(0.016, link.targetTimestamp - link.timestamp)
        var updated = bubbles
        for index in updated.indices {
            var bubble = updated[index]
            bubble.position.x += bubble.velocity.dx * delta
            bubble.position.y += bubble.velocity.dy * delta

            if bubble.position.x < -bubble.radius { bubble.position.x = bounds.width + bubble.radius }
            if bubble.position.x > bounds.width + bubble.radius { bubble.position.x = -bubble.radius }
            if bubble.position.y < -bubble.radius { bubble.position.y = bounds.height + bubble.radius }
            if bubble.position.y > bounds.height + bubble.radius { bubble.position.y = -bubble.radius }

            updated[index] = bubble
        }
        DispatchQueue.main.async {
            self.bubbles = updated
        }
    }

    private func makeBubble(for activity: Activity) -> Bubble {
        let size = bounds
        let position = CGPoint(x: CGFloat.random(in: 0...max(1, size.width)),
                               y: CGFloat.random(in: 0...max(1, size.height)))
        let velocity = CGVector(dx: CGFloat.random(in: -20...20), dy: CGFloat.random(in: -20...20))
        let radius = CGFloat.random(in: 12...20)
        return Bubble(activityName: activity.name, colorHex: activity.colorHex, position: position, velocity: velocity, radius: radius)
    }

    private func rebuildWeights(using activities: [Activity], running: Session?) {
        var cumulative: Double = 0
        weightedActivities = activities.map { activity in
            var weight = Double(max(activity.totalSeconds, 0))
            if let running,
               running.activityName.caseInsensitiveCompare(activity.name) == .orderedSame {
                weight += Double(max(running.durationSeconds, 0))
            }
            weight = max(weight, 60)
            cumulative += weight
            return (activity, cumulative)
        }
        totalWeight = cumulative
    }

    private func pickWeightedActivity(fallbackPool: [Activity]) -> Activity? {
        guard totalWeight > 0 else { return fallbackPool.randomElement() }
        let value = Double.random(in: 0..<totalWeight)
        if let match = weightedActivities.first(where: { value < $0.cumulativeWeight }) {
            return match.activity
        }
        return weightedActivities.last?.activity ?? fallbackPool.randomElement()
    }
}
