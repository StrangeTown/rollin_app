//
//  ContentView.swift
//  todaylist
//
//  Created by 尹星 on 2025/11/20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var currentDate = Date()
    
    @Query(filter: #Predicate<Item> { $0.assignedDate == nil }, sort: \Item.timestamp, order: .reverse)
    private var inboxItems: [Item]
    
    @Query(filter: #Predicate<Item> { $0.assignedDate != nil }, sort: \Item.assignedDate, order: .reverse)
    private var scheduledItems: [Item]
    
    @State private var newTaskTitle = ""

    private static let sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Inbox")) {
                    ForEach(inboxItems) { item in
                        TaskRowView(
                            item: item,
                            onToggleCompletion: { toggleCompletion(for: item) },
                            onMove: { moveToToday(item) },
                            onDelete: { deleteItem(item) },
                            isScheduled: false
                        )
                    }
                    .onDelete(perform: deleteInboxItems)
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .safeAreaInset(edge: .bottom) {
                TextField("Add new task to Inbox", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        addItem()
                    }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            List {
                if scheduledItems.isEmpty {
                    ContentUnavailableView("No scheduled tasks", systemImage: "calendar", description: Text("Move tasks from Inbox to plan your day."))
                } else {
                    ForEach(groupedItems.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatSectionHeader(date, relativeTo: currentDate))) {
                            ForEach(groupedItems[date]!) { item in
                                TaskRowView(
                                    item: item,
                                    onToggleCompletion: { toggleCompletion(for: item) },
                                    onMove: { removeFromToday(item) },
                                    onDelete: { deleteItem(item) },
                                    isScheduled: true
                                )
                            }
                            .onDelete { offsets in
                                deleteScheduledItems(at: offsets, in: groupedItems[date]!)
                            }
                        }
                    }
                }
            }
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
    }
    
    private var groupedItems: [Date: [Item]] {
        Dictionary(grouping: scheduledItems) { item in
            Calendar.current.startOfDay(for: item.assignedDate!)
        }
    }
    
    private func formatSectionHeader(_ date: Date, relativeTo referenceDate: Date) -> String {
        let calendar = Calendar.current
        let dateString = Self.sectionDateFormatter.string(from: date)
        
        if calendar.isDate(date, inSameDayAs: referenceDate) {
            return "\(dateString) (Today)"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: referenceDate)!) {
            return "\(dateString) (Yesterday)"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: referenceDate)!) {
            return "\(dateString) (Tomorrow)"
        } else {
            return dateString
        }
    }

    private func addItem() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        withAnimation {
            let newItem = Item(title: trimmedTitle)
            modelContext.insert(newItem)
            newTaskTitle = ""
        }
    }
    
    private func toggleCompletion(for item: Item) {
        withAnimation {
            item.isCompleted.toggle()
        }
    }
    
    private func moveToToday(_ item: Item) {
        withAnimation {
            item.assignedDate = Date()
        }
    }
    
    private func removeFromToday(_ item: Item) {
        withAnimation {
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
