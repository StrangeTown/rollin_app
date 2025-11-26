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
    
    @State private var showAddTaskSheet = false
    @State private var taskAssignedDate: Date? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

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
                Section(header: Text("Inbox")) {
                    ForEach(inboxItems) { item in
                        TaskRowView(
                            item: item,
                            onToggleCompletion: { toggleCompletion(for: item) },
                            onMove: { moveToToday(item) },
                            onDelete: { deleteItem(item) },
                            isScheduled: false,
                            isToday: false
                        )
                    }
                    .onDelete(perform: deleteInboxItems)
                }
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
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
