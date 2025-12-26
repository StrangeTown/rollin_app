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
    
    // Time formatter for completion time (e.g. "20:12")
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    init(currentDate: Date) {
        self.currentDate = currentDate
    }
    
    // Filter and sort today's completed items by completion time
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
    
    // Generate text for copying (Markdown format with context)
    private var copyText: String {
        todayCompletedItems.map { item in
            let time = item.completedAt.map { Self.timeFormatter.string(from: $0) } ?? ""
            let tag = item.context.map { "[\($0.name)] " } ?? ""
            return "- \(time) \(tag)\(item.title)"
        }.joined(separator: "\n")
    }
    
    @State private var showCopiedFeedback = false
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copyText, forType: .string)
        
        // Show feedback
        withAnimation {
            showCopiedFeedback = true
        }
        
        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedFeedback = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("今日时间轴")
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
                    .help("Copy all items")
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: Theme.Icons.dismiss)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Timeline content
            if todayCompletedItems.isEmpty {
                ContentUnavailableView(
                    "No completed tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Complete some tasks to see your timeline.")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(todayCompletedItems) { item in
                            TimelineItemRow(item: item, timeFormatter: Self.timeFormatter)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: 350, height: 450)
    }
}

struct TimelineItemRow: View {
    let item: Item
    let timeFormatter: DateFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 2)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Time (gray, not bold - visual noise reduction)
                if let completedAt = item.completedAt {
                    Text(timeFormatter.string(from: completedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Task title
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Context tag
                if let context = item.context {
                    Text(context.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.breadcrumbBackground)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 16)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    TodayTimelineView(currentDate: Date())
        .modelContainer(for: Item.self, inMemory: true)
}
