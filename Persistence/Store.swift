import Foundation

@MainActor
final class Store: ObservableObject {
    private let persistenceQueue = DispatchQueue(label: "StorePersistenceQueue", qos: .utility)
    private let url: URL

    @Published private(set) var activities: [Activity]
    @Published private(set) var sessions: [Session]
    @Published private(set) var dayBuckets: [DayBucket]
    @Published private(set) var runningSession: Session?

    struct Snapshot: Codable {
        var activities: [Activity]
        var sessions: [Session]
        var dayBuckets: [DayBucket]
        var runningSession: Session?
    }

    init(filename: String = "store.json") {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        url = documentURL.appendingPathComponent(filename)

        if let data = try? Data(contentsOf: url),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            activities = snapshot.activities
            sessions = snapshot.sessions
            dayBuckets = snapshot.dayBuckets
            runningSession = snapshot.runningSession
        } else {
            activities = []
            sessions = []
            dayBuckets = []
            runningSession = nil
        }
    }

    func startSession(named activityName: String?) {
        guard runningSession == nil else { return }
        let trimmed = activityName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var session = Session(activityName: trimmed, start: Date())
        if trimmed.isEmpty {
            session.activityName = ""
        } else {
            touchActivity(named: trimmed)
        }
        runningSession = session
        persist()
    }

    func stopSession(at endDate: Date = Date()) {
        guard var session = runningSession else { return }
        session.close(at: endDate)
        runningSession = session
        persist()
    }

    func finalizeSession(activityName: String) {
        let normalizedName = activityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return }
        guard var session = runningSession else { return }

        session.activityName = normalizedName
        if session.end == nil {
            session.close(at: Date())
        }

        let duration = session.durationSeconds
        let hex = colorHex(for: normalizedName)

        var updatedActivities = activities
        if let index = updatedActivities.firstIndex(where: { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }) {
            updatedActivities[index] = updatedActivities[index].adding(seconds: duration)
        } else {
            let activity = Activity(name: normalizedName,
                                    colorHex: hex,
                                    totalSeconds: duration,
                                    lastUsedAt: Date())
            updatedActivities.append(activity)
        }

        var updatedSessions = sessions
        updatedSessions.append(session)

        var updatedBuckets = dayBuckets
        if let bucketIndex = updatedBuckets.firstIndex(where: { $0.id == session.dayKey }) {
            var bucket = updatedBuckets[bucketIndex]
            let activity = updatedActivities.first { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }
                ?? Activity(name: normalizedName, colorHex: hex, totalSeconds: duration)
            bucket.append(seconds: duration, for: activity)
            updatedBuckets[bucketIndex] = bucket
        } else {
            let activity = updatedActivities.first { $0.name.caseInsensitiveCompare(normalizedName) == .orderedSame }
                ?? Activity(name: normalizedName, colorHex: hex, totalSeconds: duration)
            var bucket = DayBucket(id: session.dayKey)
            bucket.append(seconds: duration, for: activity)
            updatedBuckets.append(bucket)
            updatedBuckets.sort { $0.id < $1.id }
        }

        activities = updatedActivities
        sessions = updatedSessions
        dayBuckets = updatedBuckets
        runningSession = nil

        persist()
    }

    func touchActivity(named name: String) {
        guard let index = activities.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        activities[index].lastUsedAt = Date()
    }

    func totalSeconds(for activityName: String) -> Int {
        let base = activities.first(where: { $0.name.caseInsensitiveCompare(activityName) == .orderedSame })?.totalSeconds ?? 0
        if let running = runningSession,
           running.activityName.caseInsensitiveCompare(activityName) == .orderedSame {
            return base + running.durationSeconds
        }
        return base
    }

    func todaySlices(calendar: Calendar = .current) -> [TileSlice] {
        let key = Session.makeDayKey(from: Date(), calendar: calendar)
        return dayBuckets.first(where: { $0.id == key })?.tileSlices ?? []
    }

    private func persist() {
        let snapshot = Snapshot(activities: activities,
                                sessions: sessions,
                                dayBuckets: dayBuckets,
                                runningSession: runningSession)
        let url = self.url
        persistenceQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
