//
//  WeeklyMatrixView.swift
//  todaylist
//
//  Weekly Review - Hierarchical Bento Dashboard
//  Shows tasks grouped by Context hierarchy in a masonry layout
//

import SwiftUI
import SwiftData

// MARK: - Main View

struct WeeklyMatrixView: View {
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
    
    // Date range: past 7 days
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        return (weekAgo, today)
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
        Dictionary(grouping: weekItems.filter { $0.context != nil }) { $0.context!.id }
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
            if rootContextData.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("📊 Weekly Review")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 16) {
                StatBadge(
                    label: "Total",
                    value: "\(weekItems.count)",
                    color: Theme.Colors.todayAccent
                )
                
                StatBadge(
                    label: "Done",
                    value: "\(weekItems.filter { $0.isCompleted }.count)",
                    color: .green
                )
            }
            
            Spacer()

            // Copy Report button
            Button {
                copyFullReport()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                    Text(showCopyFeedback ? "Copied!" : "Copy Report")
                        .font(.caption)
                }
                .foregroundStyle(showCopyFeedback ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: showCopyFeedback)

            Button("Done") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No tasks this week",
            systemImage: "calendar.badge.checkmark",
            description: Text("Tasks from the past 7 days will appear here.")
        )
    }

    // MARK: - Copy Functions

    private func copyFullReport() {
        let markdown = generateFullReportMarkdown()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)

        showCopyFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopyFeedback = false
        }
    }

    private func generateFullReportMarkdown() -> String {
        var lines: [String] = []
        lines.append("# Weekly Review")
        lines.append("\(dateRangeText)")
        lines.append("")
        lines.append("**Total:** \(weekItems.count) | **Done:** \(weekItems.filter { $0.isCompleted }.count)")
        lines.append("")

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

// MARK: - Root Context Card

struct RootContextCard: View {
    let data: RootContextData
    let onCopy: (RootContextData) -> Void
    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopied = false
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
                Text("\(data.completedTaskCount)/\(data.totalTaskCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.breadcrumbBackground)
                    .clipShape(Capsule())
            }

            Divider()

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
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if data.totalTaskCount > 0 {
                        Text("\(data.completedTaskCount)/\(data.totalTaskCount)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
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
                .strikethrough(item.isCompleted, color: .secondary)
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
    WeeklyMatrixView()
        .modelContainer(for: [Item.self, ContextNode.self], inMemory: true)
}
