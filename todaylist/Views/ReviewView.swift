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
    
    // MARK: - Optimized Computed Data (Single Pass)
    
    /// All computed data in a single pass for better performance
    private var computedData: ComputedReviewData {
        ComputedReviewData(
            allItems: allScheduledItems,
            rootContexts: rootContexts,
            dateRange: dateRange
        )
    }
    
    // Masonry columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        // Capture computed data once per render
        let data = computedData
        
        VStack(spacing: 0) {
            // Header bar
            headerBar(data: data)
            
            Divider()
            
            // Bento Grid
            if !data.hasAnyContent {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Inbox card (tasks without context)
                        if !data.inboxItems.isEmpty {
                            InboxCard(items: data.inboxItems)
                        }
                        
                        // Context cards
                        ForEach(data.rootContextData) { contextData in
                            RootContextCard(data: contextData) { copiedData in
                                copyContextReport(copiedData)
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

    private func headerBar(data: ComputedReviewData) -> some View {
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
                    Text("\(data.completedCount)")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.Colors.todayAccent)
                    
                    Text("/")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                        
                    Text("\(data.totalCount)")
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
                    CopyFeedbackButton(
                        isHovered: true,
                        helpText: "Copy Report",
                        iconFont: .system(size: 14),
                        idleColor: .primary.opacity(0.7),
                        useCircleBackground: true,
                        action: copyFullReport
                    )
                    
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
        let markdown = ReviewReportBuilder.fullReportMarkdown(
            data: computedData,
            dateRangeText: dateRangeText
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }

    private func copyContextReport(_ data: RootContextData) {
        let markdown = ReviewReportBuilder.contextOnlyMarkdown(for: data)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }
}

struct ReviewReportBuilder {
    static func fullReportMarkdown(data: ComputedReviewData, dateRangeText: String) -> String {
        var lines: [String] = []
        lines.append("# Review")
        lines.append(dateRangeText)
        lines.append("")
        lines.append("**Total:** \(data.totalCount) | **Done:** \(data.completedCount)")
        lines.append("")

        if !data.inboxItems.isEmpty {
            lines.append("## Inbox")
            lines.append("")
            for item in data.inboxItems {
                let status = item.isCompleted ? "[x]" : "[ ]"
                lines.append("- \(status) \(item.title)")
            }
            lines.append("")
        }

        for contextData in data.rootContextData {
            lines.append(contentsOf: contextMarkdown(for: contextData))
        }

        return lines.joined(separator: "\n")
    }

    static func contextOnlyMarkdown(for data: RootContextData) -> String {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("(\(data.completedTaskCount)/\(data.totalTaskCount) completed)")
        lines.append("")

        for item in data.directTasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("- \(status) \(item.title)")
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, indent: ""))
        }

        return lines.joined(separator: "\n")
    }

    private static func contextMarkdown(for data: RootContextData) -> [String] {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("")

        for item in data.directTasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("- \(status) \(item.title)")
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, indent: ""))
        }

        lines.append("")
        return lines
    }

    private static func childMarkdown(for data: ChildContextData, indent: String) -> [String] {
        var lines: [String] = []
        lines.append("")
        lines.append("\(indent)### \(data.context.name)")

        for item in data.tasks {
            let status = item.isCompleted ? "[x]" : "[ ]"
            lines.append("\(indent)- \(status) \(item.title)")
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, indent: indent + "  "))
        }

        return lines
    }
}

// MARK: - Computed Review Data (Performance Optimized)

/// Aggregates all computed data in a single pass to avoid redundant calculations
struct ComputedReviewData {
    let weekItems: [Item]
    let inboxItems: [Item]
    let rootContextData: [RootContextData]
    let completedCount: Int
    let totalCount: Int
    
    var hasAnyContent: Bool {
        !rootContextData.isEmpty || !inboxItems.isEmpty
    }
    
    init(allItems: [Item], rootContexts: [ContextNode], dateRange: (start: Date, end: Date)) {
        let calendar = Calendar.current
        
        // Single pass: filter by date range and group by context
        var filtered: [Item] = []
        var byContextId: [UUID: [Item]] = [:]
        var inbox: [Item] = []
        var completed = 0
        
        for item in allItems {
            guard let date = item.assignedDate else { continue }
            let dayStart = calendar.startOfDay(for: date)
            guard dayStart >= dateRange.start && dayStart <= dateRange.end else { continue }
            
            filtered.append(item)
            if item.isCompleted { completed += 1 }
            
            if let context = item.context {
                byContextId[context.id, default: []].append(item)
            } else {
                inbox.append(item)
            }
        }
        
        self.weekItems = filtered
        self.completedCount = completed
        self.totalCount = filtered.count
        self.inboxItems = inbox.sorted { ($0.completedAt ?? $0.timestamp) > ($1.completedAt ?? $1.timestamp) }
        
        // Build hierarchical context data
        self.rootContextData = rootContexts.compactMap { root in
            let data = Self.buildContextData(for: root, itemsByContextId: byContextId)
            return data.hasAnyTasks ? data : nil
        }
    }
    
    // MARK: - Hierarchy Building (Static Methods)
    
    private static func buildContextData(for context: ContextNode, itemsByContextId: [UUID: [Item]]) -> RootContextData {
        let directTasks = itemsByContextId[context.id] ?? []
        
        var childrenData: [ChildContextData] = []
        if let children = context.children {
            for child in children.sorted(by: { $0.name < $1.name }) {
                let childData = buildChildData(for: child, itemsByContextId: itemsByContextId)
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
    
    private static func buildChildData(for context: ContextNode, itemsByContextId: [UUID: [Item]], depth: Int = 1) -> ChildContextData {
        let tasks = itemsByContextId[context.id] ?? []
        
        var nestedChildren: [ChildContextData] = []
        if let children = context.children {
            for child in children.sorted(by: { $0.name < $1.name }) {
                let childData = buildChildData(for: child, itemsByContextId: itemsByContextId, depth: depth + 1)
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
}

// MARK: - Data Models

struct RootContextData: Identifiable {
    let id: UUID
    let context: ContextNode
    let directTasks: [Item]
    let children: [ChildContextData]
    let totalTaskCount: Int
    let completedTaskCount: Int
    
    init(context: ContextNode, directTasks: [Item], children: [ChildContextData]) {
        self.id = context.id
        self.context = context
        self.directTasks = directTasks
        self.children = children
        self.totalTaskCount = directTasks.count + children.reduce(0) { $0 + $1.totalTaskCount }
        self.completedTaskCount = directTasks.filter { $0.isCompleted }.count + children.reduce(0) { $0 + $1.completedTaskCount }
    }
    
    var hasAnyTasks: Bool {
        totalTaskCount > 0
    }
}

struct ChildContextData: Identifiable {
    let id: UUID
    let context: ContextNode
    let tasks: [Item]
    let children: [ChildContextData]
    let depth: Int
    let totalTaskCount: Int
    let completedTaskCount: Int
    
    init(context: ContextNode, tasks: [Item], children: [ChildContextData], depth: Int) {
        self.id = context.id
        self.context = context
        self.tasks = tasks
        self.children = children
        self.depth = depth
        self.totalTaskCount = tasks.count + children.reduce(0) { $0 + $1.totalTaskCount }
        self.completedTaskCount = tasks.filter { $0.isCompleted }.count + children.reduce(0) { $0 + $1.completedTaskCount }
    }
    
    var hasAnyTasks: Bool {
        totalTaskCount > 0
    }
}

// MARK: - Inbox Card (for tasks without context)

struct InboxCard: View {
    let items: [Item]
    @State private var isHovered = false
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
                CopyFeedbackButton(
                    isHovered: isHovered,
                    helpText: "Copy Inbox Report",
                    action: copyInboxReport
                )

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
                CopyFeedbackButton(
                    isHovered: isHovered,
                    helpText: "Copy Context Report"
                ) {
                    onCopy(data)
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

struct CopyFeedbackButton: View {
    let isHovered: Bool
    let helpText: String
    let iconFont: Font
    let idleColor: Color
    let useCircleBackground: Bool
    let action: () -> Void

    @State private var showCopied = false
    @State private var feedbackTask: Task<Void, Never>?

    init(
        isHovered: Bool,
        helpText: String,
        iconFont: Font = .caption,
        idleColor: Color = .secondary,
        useCircleBackground: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isHovered = isHovered
        self.helpText = helpText
        self.iconFont = iconFont
        self.idleColor = idleColor
        self.useCircleBackground = useCircleBackground
        self.action = action
    }

    var body: some View {
        if isHovered || showCopied {
            Button {
                action()
                showCopied = true
                feedbackTask?.cancel()
                feedbackTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    if !Task.isCancelled {
                        showCopied = false
                    }
                }
            } label: {
                if useCircleBackground {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(iconFont)
                        .foregroundStyle(showCopied ? .green : idleColor)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                } else {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(iconFont)
                        .foregroundStyle(showCopied ? .green : idleColor)
                }
            }
            .buttonStyle(.plain)
            .transition(.opacity)
            .help(helpText)
            .onDisappear {
                feedbackTask?.cancel()
                feedbackTask = nil
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
    @State private var isCursorPushed = false

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
            if hovering && !isCursorPushed {
                NSCursor.pointingHand.push()
                isCursorPushed = true
            } else if !hovering && isCursorPushed {
                NSCursor.pop()
                isCursorPushed = false
            }
        }
        .onDisappear {
            if isCursorPushed {
                NSCursor.pop()
                isCursorPushed = false
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
