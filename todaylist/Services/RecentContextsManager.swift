import Foundation

struct RecentContextsManager {
    private static let key = "recentContextIDs"
    private static let maxCount = 5

    static var recentIDs: [UUID] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let strings = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    static func record(_ id: UUID) {
        var ids = recentIDs
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > maxCount { ids = Array(ids.prefix(maxCount)) }
        let strings = ids.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(strings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
