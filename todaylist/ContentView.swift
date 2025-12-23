//
//  ContentView.swift
//  todaylist
//
//  Created by 尹星 on 2025/11/20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: - Environment & State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    // Tracks the current date to handle day changes (e.g. midnight)
    @State private var currentDate = Date()
    
    // MARK: - Data Queries
    // Fetch items that are not assigned to any date (Inbox)
    @Query(filter: #Predicate<Item> { $0.assignedDate == nil }, sort: \Item.timestamp, order: .reverse)
    private var inboxItems: [Item]
    
    // Fetch items that have an assigned date (Scheduled/Today)
    @Query(filter: #Predicate<Item> { $0.assignedDate != nil }, sort: \Item.assignedDate, order: .reverse)
    private var scheduledItems: [Item]
    
    // Fetch root contexts
    @Query(filter: #Predicate<ContextNode> { $0.parent == nil }, sort: \ContextNode.name)
    private var rootContexts: [ContextNode]
    
    @State private var selectedContext: ContextNode?
    @State private var showAddContextAlert = false
    @State private var newContextName = ""
    @State private var contextParentForAdd: ContextNode?
    
    @State private var showAddTaskSheet = false
    @State private var taskAssignedDate: Date? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showTimelineSheet = false
    
    @State private var taskToEdit: Item?

    // Date formatter for section headers (e.g. "11.20")
    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()
    
    // Date formatter for day of week (e.g. "Monday")
    private static let dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar (Inbox)
            List {
                inboxSection
                contextSection
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .toolbar {
                ToolbarItem {
                    if columnVisibility != .detailOnly {
                        Button(action: { 
                            taskAssignedDate = nil
                            showAddTaskSheet = true 
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                        .help("Add new task to Inbox (⌘I)")
                        .keyboardShortcut("i", modifiers: .command)
                    }
                }
            }
        } detail: {
            if let context = selectedContext {
                ContextDetailView(context: context, taskToEdit: $taskToEdit)
            } else {
                // MARK: - Detail View (Scheduled Tasks)
                List {
                if scheduledItems.isEmpty {
                    ContentUnavailableView("No scheduled tasks", systemImage: "calendar", description: Text("Move tasks from Inbox to plan your day."))
                } else {
                    ForEach(groupedItems.keys.sorted(by: >), id: \.self) { date in
                        // Group tasks by date (Today, Yesterday, etc.)
                        Section(header: 
                            HStack {
                                Text(formatSectionHeader(date, relativeTo: currentDate))
                                if Calendar.current.isDate(date, inSameDayAs: currentDate) {
                                    Spacer()
                                    Button(action: {
                                        showTimelineSheet = true
                                    }) {
                                        Image(systemName: "clock")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("View today's timeline")
                                    
                                    Button(action: {
                                        taskAssignedDate = currentDate
                                        showAddTaskSheet = true
                                    }) {
                                        Image(systemName: "plus")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Add task to Today (⌘T)")
                                }
                            }
                        ) {
                            ForEach(groupedItems[date]!) { item in
                                TaskRowView(
                                    item: item,
                                    onToggleCompletion: { toggleCompletion(for: item) },
                                    onMove: { removeFromToday(item) },
                                    onDelete: { deleteItem(item) },
                                    onEdit: {
                                        taskToEdit = item
                                    },
                                    isScheduled: true,
                                    isToday: Calendar.current.isDate(date, inSameDayAs: currentDate)
                                )
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                deleteScheduledItems(at: offsets, in: groupedItems[date]!)
                            }
                        }
                    }
                }
            }
        }
        }
        .alert("New Context", isPresented: $showAddContextAlert) {
            TextField("Name", text: $newContextName)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addContext(name: newContextName, parent: contextParentForAdd)
            }
        }
        // MARK: - Lifecycle & Events
        .background {
            if columnVisibility == .detailOnly {
                Button("Add Task") {
                    taskAssignedDate = nil
                    showAddTaskSheet = true
                }
                .keyboardShortcut("i", modifiers: .command)
                .hidden()
            }
            
            Button("Add to Today") {
                taskAssignedDate = currentDate
                showAddTaskSheet = true
            }
            .keyboardShortcut("t", modifiers: .command)
            .hidden()
        }
        .onAppear {
            currentDate = Date()
            moveOverdueTasksToInbox()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                currentDate = Date()
                moveOverdueTasksToInbox()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            currentDate = Date()
            moveOverdueTasksToInbox()
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskView(assignedDate: taskAssignedDate)
        }
        .sheet(isPresented: $showTimelineSheet) {
            TodayTimelineView(currentDate: currentDate)
        }
        .sheet(item: $taskToEdit) { item in
            EditTaskView(item: item)
        }
    }
    
    // MARK: - Computed Properties
    
    // Groups scheduled items by their assigned date (ignoring time)
    private var groupedItems: [Date: [Item]] {
        Dictionary(grouping: scheduledItems) { item in
            Calendar.current.startOfDay(for: item.assignedDate!)
        }
    }
    
    // MARK: - Helper Methods
    
    // Formats the date header with relative terms (Today, Yesterday, Tomorrow)
    private func formatSectionHeader(_ date: Date, relativeTo referenceDate: Date) -> String {
        let calendar = Calendar.current
        let dateString = Self.sectionDateFormatter.string(from: date)
        
        if calendar.isDate(date, inSameDayAs: referenceDate) {
            return "\(dateString)   Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: referenceDate)!) {
            return "\(dateString)   Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: referenceDate)!) {
            return "\(dateString)   Tomorrow"
        } else {
            let dayOfWeek = Self.dayOfWeekFormatter.string(from: date)
            return "\(dateString)   \(dayOfWeek)"
        }
    }

    private func toggleCompletion(for item: Item) {
        withAnimation {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
        }
    }
    
    private func moveToToday(_ item: Item) {
        withAnimation {
            // Assign current date to move from Inbox to Today
            item.assignedDate = Date()
        }
    }
    
    private func removeFromToday(_ item: Item) {
        withAnimation {
            // Remove assigned date to move back to Inbox
            item.assignedDate = nil
        }
    }

    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }

    private func deleteInboxItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(inboxItems[index])
            }
        }
    }
    
    private func deleteScheduledItems(at offsets: IndexSet, in items: [Item]) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
    
    // Moves uncompleted tasks from past dates back to Inbox
    private func moveOverdueTasksToInbox() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDate)
        
        let overdueItems = scheduledItems.filter { item in
            guard let date = item.assignedDate else { return false }
            return !item.isCompleted && calendar.startOfDay(for: date) < startOfToday
        }
        
        withAnimation {
            for item in overdueItems {
                item.assignedDate = nil
            }
        }
    }
    
    func addContext(name: String, parent: ContextNode?) {
        let context = ContextNode(name: name, parent: parent)
        modelContext.insert(context)
    }
    
    func deleteContext(_ context: ContextNode) {
        modelContext.delete(context)
        if selectedContext == context {
            selectedContext = nil
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private var inboxSection: some View {
        Section(header: Text("Inbox")) {
            ForEach(inboxItems) { item in
                TaskRowView(
                    item: item,
                    onToggleCompletion: { toggleCompletion(for: item) },
                    onMove: { moveToToday(item) },
                    onDelete: { deleteItem(item) },
                    onEdit: {
                        taskToEdit = item
                    },
                    isScheduled: false,
                    isToday: false
                )
            }
            .onDelete(perform: deleteInboxItems)
        }
    }
    
    @ViewBuilder
    private var contextSection: some View {
        Section(header: contextSectionHeader) {
            ForEach(rootContexts) { node in
                ContextTreeRow(
                    node: node,
                    selectedContext: $selectedContext,
                    contextParentForAdd: $contextParentForAdd,
                    newContextName: $newContextName,
                    showAddContextAlert: $showAddContextAlert,
                    onDelete: deleteContext
                )
            }
        }
    }

    private var contextSectionHeader: some View {
        HStack {
            Text("Contexts")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                contextParentForAdd = nil
                newContextName = ""
                showAddContextAlert = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 4)
    }

}

// MARK: - Context Tree Row with collapsible children
struct ContextTreeRow: View {
    let node: ContextNode
    @Binding var selectedContext: ContextNode?
    @Binding var contextParentForAdd: ContextNode?
    @Binding var newContextName: String
    @Binding var showAddContextAlert: Bool
    let onDelete: (ContextNode) -> Void
    
    @State private var isHovering = false
    
    private var hasChildren: Bool {
        node.children?.isEmpty == false
    }
    
    var body: some View {
        if hasChildren {
            // 有子节点：使用 DisclosureGroup
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children.sorted(by: { $0.name < $1.name }), id: \.id) { childNode in
                        ContextTreeRow(
                            node: childNode,
                            selectedContext: $selectedContext,
                            contextParentForAdd: $contextParentForAdd,
                            newContextName: $newContextName,
                            showAddContextAlert: $showAddContextAlert,
                            onDelete: onDelete
                        )
                    }
                }
            } label: {
                nodeContent
            }
        } else {
            // 无子节点：直接显示内容
            nodeContent
        }
    }
    
    private var nodeContent: some View {
        HStack {
            Image(systemName: hasChildren ? "circle.fill" : "circle")
                .foregroundStyle(selectedContext == node ? .white : .secondary)
                .font(.system(size: 8))
            
            Text(node.name)
                .foregroundStyle(selectedContext == node ? .white : .primary)
            
            Spacer()
            
            if let items = node.items, !items.isEmpty {
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(selectedContext == node ? .white.opacity(0.9) : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(selectedContext == node ? .white.opacity(0.25) : Color.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(selectedContext == node ? Color.accentColor : (isHovering ? Color.primary.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedContext == node {
                selectedContext = nil
            } else {
                selectedContext = node
            }
        }
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Add Child Context") {
                contextParentForAdd = node
                newContextName = ""
                showAddContextAlert = true
            }
            Button("Delete", role: .destructive) {
                onDelete(node)
            }
        }
    }
}

struct ContextDetailView: View {
    let context: ContextNode
    @Query var items: [Item]
    @Environment(\.modelContext) private var modelContext
    @Binding var taskToEdit: Item?
    
    init(context: ContextNode, taskToEdit: Binding<Item?>) {
        self.context = context
        _taskToEdit = taskToEdit
        let targetId = context.id
        // Filter items by context ID
        _items = Query(filter: #Predicate<Item> { item in
            item.context?.id == targetId
        }, sort: \Item.timestamp, order: .reverse)
    }
    
    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView("No items in context", systemImage: "circle.dotted", description: Text("Add items to this context."))
            } else {
                ForEach(items) { item in
                    TaskRowView(
                        item: item,
                        onToggleCompletion: { toggleCompletion(for: item) },
                        onMove: { moveToToday(item) },
                        onDelete: { deleteItem(item) },
                        onEdit: {
                            taskToEdit = item
                        },
                        isScheduled: item.assignedDate != nil,
                        isToday: false
                    )
                }
            }
        }
        .navigationTitle(context.name)
    }
    
    private func toggleCompletion(for item: Item) {
        withAnimation {
            item.isCompleted.toggle()
            item.completedAt = item.isCompleted ? Date() : nil
        }
    }
    
    private func moveToToday(_ item: Item) {
        withAnimation {
            item.assignedDate = Date()
        }
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

