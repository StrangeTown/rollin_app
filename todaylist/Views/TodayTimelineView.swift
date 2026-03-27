//
//  TodayTimelineView.swift
//  todaylist
//
//  Created by 尹星 on 2025/12/9.
//

import SwiftUI
import SwiftData
import AppKit

struct TodayTimelineView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allItems: [Item]

    private let currentDate: Date

    /// Sentinel UUID representing tasks with no context in the filter set.
    private static let nilContextID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    init(currentDate: Date) {
        self.currentDate = currentDate
    }

    // MARK: - Data

    private var todayCompletedItems: [Item] {
        let calendar = Calendar.current
        return allItems
            .filter { item in
                guard item.isCompleted,
                      let assignedDate = item.assignedDate,
                      item.completedAt != nil else { return false }
                return calendar.isDate(assignedDate, inSameDayAs: currentDate)
            }
            .sorted { ($0.completedAt ?? Date.distantPast) < ($1.completedAt ?? Date.distantPast) }
    }

    /// Ordered unique filter entries derived from today's completed items.
    private var availableFilterEntries: [(id: UUID, name: String)] {
        var entries: [(UUID, String)] = []
        var seen = Set<UUID>()
        for item in todayCompletedItems {
            let id = item.context?.id ?? Self.nilContextID
            let name = item.context?.fullPath ?? "无上下文"
            if seen.insert(id).inserted {
                entries.append((id, name))
            }
        }
        return entries
    }

    /// nil = all selected (default); non-nil = only the listed IDs are shown.
    @State private var selectedFilterIDs: Set<UUID>? = nil

    private var filteredItems: [Item] {
        guard let selected = selectedFilterIDs else { return todayCompletedItems }
        return todayCompletedItems.filter { item in
            let id = item.context?.id ?? Self.nilContextID
            return selected.contains(id)
        }
    }

    private func toggleFilter(_ id: UUID) {
        let allIDs = Set(availableFilterEntries.map(\.id))
        if selectedFilterIDs == nil {
            // All currently selected → isolate to just this one
            selectedFilterIDs = [id]
        } else {
            var current = selectedFilterIDs!
            if current.contains(id) {
                current.remove(id)
                selectedFilterIDs = current.isEmpty ? nil : current
            } else {
                current.insert(id)
                selectedFilterIDs = current == allIDs ? nil : current
            }
        }
    }

    // MARK: - Copy

    private var copyText: String {
        filteredItems.map { item in
            let time = item.completedAt.map { Self.timeFormatter.string(from: $0) } ?? ""
            let tag = item.context.map { "[\($0.name)] " } ?? ""
            let duration = item.hasBeenTracked
                ? " (\(ElapsedTimeView.formatDuration(item.accumulatedDuration)))"
                : ""
            return "- \(time)\(duration) \(tag)\(item.title)"
        }.joined(separator: "\n")
    }

    @State private var showCopiedFeedback = false

    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copyText, forType: .string)
        withAnimation { showCopiedFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopiedFeedback = false }
        }
    }

    // MARK: - Views

    @ViewBuilder
    private var contextFilterBar: some View {
        if availableFilterEntries.count > 1 {
            FlowLayout(spacing: 6) {
                // "全部" chip
                let allSelected = selectedFilterIDs == nil
                Button { selectedFilterIDs = nil } label: {
                    Text("全部")
                        .font(.caption)
                        .fontWeight(allSelected ? .medium : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(allSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                        .foregroundStyle(allSelected ? Color.white : Color.secondary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                ForEach(availableFilterEntries, id: \.id) { entry in
                    let isSelected = selectedFilterIDs == nil || selectedFilterIDs!.contains(entry.id)
                    Button { toggleFilter(entry.id) } label: {
                        Text(entry.name)
                            .font(.caption)
                            .fontWeight(isSelected ? .medium : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.07))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)

            Divider()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("任务时间轴")
                    .font(.headline)
                Spacer()

                if showCopiedFeedback {
                    Text("已复制")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }

                if !todayCompletedItems.isEmpty {
                    Button(action: copyToClipboard) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : Theme.Icons.copy)
                            .foregroundColor(showCopiedFeedback ? .green : nil)
                    }
                    .buttonStyle(.plain)
                    .help("Copy filtered items")
                }

                Button(action: { dismiss() }) {
                    Image(systemName: Theme.Icons.dismiss)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            contextFilterBar

            // Timeline content
            if todayCompletedItems.isEmpty {
                ContentUnavailableView(
                    "No completed tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Complete some tasks to see your timeline.")
                )
                .frame(maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                ContentUnavailableView(
                    "无匹配任务",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("当前过滤条件下没有任务。")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredItems) { item in
                            TimelineItemRow(item: item, timeFormatter: Self.timeFormatter)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .frame(width: 350, height: 450)
        .onChange(of: todayCompletedItems.map(\.id)) { _, _ in
            // Reset filter if selected contexts no longer exist in new data
            guard let selected = selectedFilterIDs else { return }
            let available = Set(availableFilterEntries.map(\.id))
            let stillValid = selected.intersection(available)
            selectedFilterIDs = stillValid.isEmpty || stillValid == available ? nil : stillValid
        }
    }
}

struct TimelineItemRow: View {
    let item: Item
    let timeFormatter: DateFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator - refined
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 1.5)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Time + duration + context on one line
                if let completedAt = item.completedAt {
                    HStack(spacing: 4) {
                        Text(timeFormatter.string(from: completedAt))
                        if item.hasBeenTracked {
                            Text("· \(ElapsedTimeView.formatDuration(item.accumulatedDuration))")
                        }
                        if let context = item.context {
                            Text("·")
                            Text(context.fullPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(Theme.Colors.timelineTimestamp)
                }

                // Task title - soft charcoal
                Text(item.title)
                    .font(.body)
                    .foregroundColor(Theme.Colors.timelineText)
            }
            .padding(.bottom, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    TodayTimelineView(currentDate: Date())
        .modelContainer(for: Item.self, inMemory: true)
}
