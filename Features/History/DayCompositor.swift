import Foundation

struct DayCompositor {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func compose(from sessions: [Session], activities: [Activity]) -> [DayBucket] {
        var buckets: [String: DayBucket] = [:]
        for session in sessions {
            guard let activity = activities.first(where: { $0.name.caseInsensitiveCompare(session.activityName) == .orderedSame }) else { continue }
            var bucket = buckets[session.dayKey] ?? DayBucket(id: session.dayKey)
            bucket.append(seconds: session.durationSeconds, for: activity)
            buckets[session.dayKey] = bucket
        }
        return buckets.values.sorted { $0.id < $1.id }
    }
}
