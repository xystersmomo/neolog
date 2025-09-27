import Foundation

struct Session: Identifiable, Codable {
    var id: UUID
    var activityName: String
    var start: Date
    var end: Date?
    var dayKey: String

    init(id: UUID = UUID(), activityName: String, start: Date = Date(), end: Date? = nil, dayKey: String? = nil) {
        self.id = id
        self.activityName = activityName
        self.start = start
        self.end = end
        self.dayKey = dayKey ?? Self.makeDayKey(from: start)
    }

    var durationSeconds: Int {
        max(0, Int((end ?? Date()).timeIntervalSince(start)))
    }

    var isRunning: Bool { end == nil }

    mutating func close(at endDate: Date) {
        guard end == nil else { return }
        end = endDate
    }

    static func makeDayKey(from date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
}
