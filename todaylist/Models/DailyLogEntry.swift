//
//  DailyLogEntry.swift
//  todaylist
//

import Foundation
import SwiftUI
import Combine

// MARK: - Model

struct DailyLogEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let content: String
    let linkedTaskId: String?    // Item's persistentModelID string
    let linkedTaskTitle: String? // Denormalized for display

    init(content: String, linkedTaskId: String? = nil, linkedTaskTitle: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.content = content
        self.linkedTaskId = linkedTaskId
        self.linkedTaskTitle = linkedTaskTitle
    }
}

// MARK: - Manager

@MainActor
final class DailyLogManager: ObservableObject {
    static let shared = DailyLogManager()

    @Published private(set) var entries: [DailyLogEntry] = []

    private let entriesKey = "dailyLogEntries"
    private let dateKey = "dailyLogDate"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var todayString: String {
        Self.dateFormatter.string(from: Date())
    }

    private init() {
        loadAndValidate()
    }

    // Load entries from UserDefaults; clear if stored date != today
    func loadAndValidate() {
        let storedDate = UserDefaults.standard.string(forKey: dateKey) ?? ""
        if storedDate != todayString {
            clearAll()
        } else {
            if let data = UserDefaults.standard.data(forKey: entriesKey),
               let decoded = try? JSONDecoder().decode([DailyLogEntry].self, from: data) {
                entries = decoded
            } else {
                entries = []
            }
        }
    }

    func addEntry(_ entry: DailyLogEntry) {
        loadAndValidate()
        entries.append(entry)
        persist()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
        UserDefaults.standard.set(todayString, forKey: dateKey)
    }

    private func clearAll() {
        entries = []
        UserDefaults.standard.removeObject(forKey: entriesKey)
        UserDefaults.standard.set(todayString, forKey: dateKey)
    }
}
