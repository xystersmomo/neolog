import Foundation

struct Activity: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var colorHex: String
    var totalSeconds: Int
    var lastUsedAt: Date?

    init(id: UUID = UUID(), name: String, colorHex: String, totalSeconds: Int = 0, lastUsedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.totalSeconds = totalSeconds
        self.lastUsedAt = lastUsedAt
    }

    var displayName: String { name }

    func adding(seconds: Int) -> Activity {
        Activity(id: id,
                 name: name,
                 colorHex: colorHex,
                 totalSeconds: totalSeconds + seconds,
                 lastUsedAt: Date())
    }
}

extension Array where Element == Activity {
    func sortedByRecent() -> [Activity] {
        sorted { lhs, rhs in
            switch (lhs.lastUsedAt, rhs.lastUsedAt) {
            case let (l?, r?):
                return l > r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
}
