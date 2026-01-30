//
//  ReviewView.swift
//  todaylist
//
//  Review Dashboard - Hierarchical Bento Dashboard
//  Shows tasks grouped by Context hierarchy in a masonry layout
//  Supports custom date range selection
//

import SwiftUI
import SwiftData

// MARK: - Date Range Preset

enum DateRangePreset: String, CaseIterable {
    case week = "Past 7 Days"
    case twoWeeks = "Past 14 Days"
    case month = "Past 30 Days"

    var days: Int {
        switch self {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        }
    }
}

// MARK: - Main View

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Fetch root contexts (parent == nil)
    @Query(filter: #Predicate<ContextNode> { $0.parent == nil }, sort: \ContextNode.name)
    private var rootContexts: [ContextNode]

    // Fetch all items with assigned dates
    @Query(filter: #Predicate<Item> { $0.assignedDate != nil })
    private var allScheduledItems: [Item]

    // Copy feedback state
    @State private var showCopyFeedback = false
    @State private var copyFeedbackTask: Task<Void, Never>?

    // Date range selection
    @State private var selectedPreset: DateRangePreset = .week

    // Static DateFormatter for performance
    private static let dateRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()
    
    // Computed date range based on selection
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(selectedPreset.days - 1), to: today) ?? today
        return (start, today)
    }
    
    // Filter items within the week
    private var weekItems: [Item] {
        let calendar = Calendar.current
        return allScheduledItems.filter { item in
            guard let date = item.assignedDate else { return false }
            let dayStart = calendar.startOfDay(for: date)
            return dayStart >= dateRange.start && dayStart <= dateRange.end
        }
    }
    
    // Group items by context ID for quick lookup
    private var itemsByContextId: [UUID: [Item]] {
        Dictionary(grouping: weekItems.compactMap { item -> (UUID, Item)? in
            guard let context = item.context else { return nil }
            return (context.id, item)
        }) { $0.0 }.mapValues { $0.map { $0.1 } }
    }
    
    // Items without any context (Inbox items)
    private var inboxItems: [Item] {
        weekItems.filter { $0.context == nil }
            .sorted { ($0.completedAt ?? $0.timestamp) > ($1.completedAt ?? $1.timestamp) }
    }
    
    // Check if there's any content to show
    private var hasAnyContent: Bool {
        !rootContextData.isEmpty || !inboxItems.isEmpty
    }
    
    // Build hierarchical data for each root context
    private var rootContextData: [RootContextData] {
        rootContexts.compactMap { root in
            let data = buildContextData(for: root)
            // Only include if there are any tasks
            if data.hasAnyTasks {
                return data
            }
            return nil
        }
    }
    
    private func buildContextData(for context: ContextNode) -> RootContextData {
        let directTasks = itemsByContextId[context.id] ?? []
        
        var childrenData: [ChildContextData] = []
        if let children = context.children {
            for child in children.sorted(by: { $0.name < $1.name }) {
                let childData = buildChildData(for: child)
                if childData.hasAnyTasks {
                    childrenData.append(childData)
                }
            }
        }
        
        return RootContextData(
            context: context,
            directTasks: directTasks.sorted { ($0.completedAt ?? $0.timestamp) > ($1.completedAt ?? $1.timestamp) },
            children: childrenData
        )
    }
    
    private func buildChildData(for context: ContextNode, depth: Int = 1) -> ChildContextData {
        let tasks = itemsByContextId[context.id] ?? []
        
        var nestedChildren: [ChildContextData] = []
        if let children = context.children {
            for child in children.sorted(by: { $0.name < $1.name }) {
                let childData = buildChildData(for: child, depth: depth + 1)
                if childData.hasAnyTasks {
                    nestedChildren.append(childData)
                }
            }
        }
        
        return ChildContextData(
            context: context,
            tasks: tasks.sorted { ($0.completedAt ?? $0.timestamp) > ($1.completedAt ?? $1.timestamp) },
            children: nestedChildren,
            depth: depth
        )
    }
    
    // Masonry columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar
            
            Divider()
            
            // Bento Grid
            if !hasAnyContent {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Inbox card (tasks without context)
                        if !inboxItems.isEmpty {
                            InboxCard(items: inboxItems)
                        }
                        
                        // Context cards
                        ForEach(rootContextData) { data in
                            RootContextCard(data: data) { contextData in
                                copyContextReport(contextData)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 20) {
            // Left: Title and Date
            VStack(alignment: .leading, spacing: 4) {
                Text("Review")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Menu {
                        ForEach(DateRangePreset.allCases, id: \.self) { preset in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPreset = preset
                                }
                            } label: {
                                HStack {
                                    Text(preset.rawValue)
                                    if selectedPreset == preset {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(selectedPreset.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                    .menuStyle(.borderlessButton)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(dateRangeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Right: Actions
            HStack(spacing: 24) {
                // Key Metric
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(weekItems.filter { $0.isCompleted }.count)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.todayAccent)
                    
                    Text("/")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                        
                    Text("\(weekItems.count)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button {
                        copyFullReport()
                    } label: {
                        Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(showCopyFeedback ? .green : .primary.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Copy Report")
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.todayAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.Colors.todayAccent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var dateRangeText: String {
        "\(Self.dateRangeFormatter.string(from: dateRange.start)) - \(Self.dateRangeFormatter.string(from: dateRange.end))"
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No tasks in this period",
            systemImage: "calendar.badge.checkmark",
            description: Text("Tasks from \(dateRangeText) will appear here.")
        )
    }

    // MARK: - Copy Functions

    private func copyFullReport() {
        let markdown = generateFullReportMarkdown()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)

        showCopyFeedback = true
        copyFeedbackTask?.cancel()
        copyFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if !Task.isCancelled {
                showCopyFeedback = false
            }
        }
    }

    private func generateFullReportMarkdown() -> String {
        var lines: [String] = []
        lines.append("# Review")
        lines.append("\(dateRangeText)")
        lines.append("")
        lines.append("**Total:** \(weekItems.count) | **Done:** \(weekItems.filter { $0.isCompleted }.count)")
        lines.append("")

        // Inbox items (no context)
        if !inboxItems.isEmpty {
            lines.append("## Inbox")
            lines.append("")
            for item in inboxItems {
                let status = item.isCompleted ? "[x]" : "[ ]"
                lines.append("- \(status) \(item.title)")
            }
            lines.append("")
        }

        for data in rootContextData {
            lines.append(contentsOf: generateContextMarkdown(for: data))
        }

        return lines.joined(separator: "\n")
    }

    private func generateContextMarkdown(for data: RootContextData) -> [String] {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("")

        // Direct tasks
        for item in data.directTasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("- \(status) \(item.title)")
        }

        // Children
        for child in data.children {
            lines.append(contentsOf: generateChildMarkdown(for: child, indent: ""))
        }

        lines.append("")
        return lines
    }

    private func generateChildMarkdown(for data: ChildContextData, indent: String) -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(indent)### \(data.context.name)")

        for item in data.tasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("\(indent)- \(status) \(item.title)")
        }

        for child in data.children {
            lines.append(contentsOf: generateChildMarkdown(for: child, indent: indent + "  "))
        }

        return lines
    }

    func generateContextOnlyMarkdown(for data: RootContextData) -> String {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("(\(data.completedTaskCount)/\(data.totalTaskCount) completed)")
        lines.append("")

        for item in data.directTasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("- \(status) \(item.title)")
        }

        for child in data.children {
            lines.append(contentsOf: generateChildMarkdown(for: child, indent: ""))
        }

        return lines.joined(separator: "\n")
    }

    private func copyContextReport(_ data: RootContextData) {
        let markdown = generateContextOnlyMarkdown(for: data)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }
}

// MARK: - Data Models

struct RootContextData: Identifiable {
    let id: UUID
    let context: ContextNode
    let directTasks: [Item]
    let children: [ChildContextData]
    
    init(context: ContextNode, directTasks: [Item], children: [ChildContextData]) {
        self.id = context.id
        self.context = context
        self.directTasks = directTasks
        self.children = children
    }
    
    var hasAnyTasks: Bool {
        !directTasks.isEmpty || children.contains { $0.hasAnyTasks }
    }
    
    var totalTaskCount: Int {
        directTasks.count + children.reduce(0) { $0 + $1.totalTaskCount }
    }
    
    var completedTaskCount: Int {
        directTasks.filter { $0.isCompleted }.count + children.reduce(0) { $0 + $1.completedTaskCount }
    }
}

struct ChildContextData: Identifiable {
    let id: UUID
    let context: ContextNode
    let tasks: [Item]
    let children: [ChildContextData]
    let depth: Int
    
    init(context: ContextNode, tasks: [Item], children: [ChildContextData], depth: Int) {
        self.id = context.id
        self.context = context
        self.tasks = tasks
        self.children = children
        self.depth = depth
    }
    
    var hasAnyTasks: Bool {
        !tasks.isEmpty || children.contains { $0.hasAnyTasks }
    }
    
    var totalTaskCount: Int {
        tasks.count + children.reduce(0) { $0 + $1.totalTaskCount }
    }
    
    var completedTaskCount: Int {
        tasks.filter { $0.isCompleted }.count + children.reduce(0) { $0 + $1.completedTaskCount }
    }
}

// MARK: - Inbox Card (for tasks without context)

struct InboxCard: View {
    let items: [Item]
    @State private var isHovered = false
    @State private var showCopied = false
    @State private var copyTask: Task<Void, Never>?
    @State private var showAllTasks = false
    private let maxVisibleTasks = 8
    
    private var visibleItems: [Item] {
        showAllTasks ? items : Array(items.prefix(maxVisibleTasks))
    }
    
    private var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "tray.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text("Inbox")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Copy button (shows on hover)
                if isHovered || showCopied {
                    Button {
                        copyInboxReport()
                        showCopied = true
                        copyTask?.cancel()
                        copyTask = Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            if !Task.isCancelled {
                                showCopied = false
                            }
                        }
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(showCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                // Progress indicator
                HStack(spacing: 3) {
                    Text("\(completedCount)")
                        .fontWeight(.semibold)
                        .foregroundStyle(completedCount == items.count ? .green : .primary)
                    Text("/")
                        .foregroundStyle(.tertiary)
                    Text("\(items.count)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.Colors.breadcrumbBackground)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.08))

            // Content area
            VStack(alignment: .leading, spacing: 6) {
                ForEach(visibleItems) { item in
                    TaskRow(item: item)
                }
                
                // Show more button if needed
                if items.count > maxVisibleTasks && !showAllTasks {
                    ShowMoreButton(
                        remainingCount: items.count - maxVisibleTasks,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAllTasks = true
                            }
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func copyInboxReport() {
        var lines: [String] = []
        lines.append("## Inbox")
        lines.append("(\(completedCount)/\(items.count) completed)")
        lines.append("")
        
        for item in items {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("- \(status) \(item.title)")
        }
        
        let markdown = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }
}

// MARK: - Root Context Card

struct RootContextCard: View {
    let data: RootContextData
    let onCopy: (RootContextData) -> Void
    @State private var isHovered = false
    @State private var showCopied = false
    @State private var copyTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with subtle background
            HStack {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.todayAccent)

                Text(data.context.name)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Copy button (shows on hover)
                if isHovered || showCopied {
                    Button {
                        onCopy(data)
                        showCopied = true
                        copyTask?.cancel()
                        copyTask = Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            if !Task.isCancelled {
                                showCopied = false
                            }
                        }
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(showCopied ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                // Progress indicator - enhanced style
                HStack(spacing: 3) {
                    Text("\(data.completedTaskCount)")
                        .fontWeight(.semibold)
                        .foregroundStyle(data.completedTaskCount == data.totalTaskCount ? .green : .primary)
                    Text("/")
                        .foregroundStyle(.tertiary)
                    Text("\(data.totalTaskCount)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Theme.Colors.breadcrumbBackground)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.Colors.todayAccent.opacity(0.05))

            // Content area
            VStack(alignment: .leading, spacing: 10) {
                // Direct tasks (if any)
                if !data.directTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(data.directTasks) { item in
                            TaskRow(item: item)
                        }
                    }
                }

                // Child contexts
                ForEach(data.children) { child in
                    ChildContextBlock(data: child)
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Child Context Block

struct ChildContextBlock: View {
    let data: ChildContextData
    @State private var isExpanded: Bool = true
    @State private var showAllTasks: Bool = false
    private let maxVisibleTasks = 5

    private var visibleTasks: [Item] {
        showAllTasks ? data.tasks : Array(data.tasks.prefix(maxVisibleTasks))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with connector - clickable to toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 10)

                    Text(data.context.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary.opacity(0.8))

                    Spacer()

                    if data.totalTaskCount > 0 {
                        HStack(spacing: 2) {
                            Text("\(data.completedTaskCount)")
                                .foregroundStyle(data.completedTaskCount == data.totalTaskCount ? .green : .secondary)
                            Text("/")
                                .foregroundStyle(.tertiary)
                            Text("\(data.totalTaskCount)")
                                .foregroundStyle(.tertiary)
                        }
                        .font(.caption2)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Tasks with left border line style
                if !data.tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(visibleTasks) { item in
                            TaskRow(item: item, isNested: true)
                        }

                        // Show more button if needed
                        if data.tasks.count > maxVisibleTasks && !showAllTasks {
                            ShowMoreButton(
                                remainingCount: data.tasks.count - maxVisibleTasks,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showAllTasks = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.leading, 16)
                }

                // Nested children (recursive)
                ForEach(data.children) { child in
                    ChildContextBlock(data: child)
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            // Left border line (quote style)
            Rectangle()
                .fill(Theme.Colors.todayAccent.opacity(0.4))
                .frame(width: 2)
        }
    }
}

// MARK: - Show More Button

struct ShowMoreButton: View {
    let remainingCount: Int
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "ellipsis")
                    .font(.caption2)
                Text("Show \(remainingCount) more...")
                    .font(.caption)
            }
            .foregroundStyle(isHovered ? Theme.Colors.todayAccent : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Theme.Colors.todayAccent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let item: Item
    var isNested: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            // Status indicator
            Circle()
                .fill(item.isCompleted ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 5, height: 5)

            // Title
            Text(item.title)
                .font(isNested ? .caption : .callout)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewView()
        .modelContainer(for: [Item.self, ContextNode.self], inMemory: true)
}
