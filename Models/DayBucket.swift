import Foundation

struct TileSlice: Identifiable, Hashable, Codable {
    var id: UUID
    var activityName: String
    var colorHex: String
    var seconds: Int

    init(id: UUID = UUID(), activityName: String, colorHex: String, seconds: Int) {
        self.id = id
        self.activityName = activityName
        self.colorHex = colorHex
        self.seconds = seconds
    }
}

struct DayBucket: Identifiable, Codable {
    var id: String
    var tileSlices: [TileSlice]

    init(id: String, tileSlices: [TileSlice] = []) {
        self.id = id
        self.tileSlices = tileSlices
    }

    mutating func append(seconds: Int, for activity: Activity) {
        guard seconds > 0 else { return }
        if var last = tileSlices.last, last.activityName.caseInsensitiveCompare(activity.name) == .orderedSame {
            last.seconds += seconds
            tileSlices.removeLast()
            tileSlices.append(last)
        } else {
            let slice = TileSlice(activityName: activity.name, colorHex: activity.colorHex, seconds: seconds)
            tileSlices.append(slice)
        }
    }
}

extension Array where Element == DayBucket {
    func bucket(for dayKey: String) -> DayBucket? {
        first { $0.id == dayKey }
    }
}
