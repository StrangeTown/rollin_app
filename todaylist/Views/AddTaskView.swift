import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var assignedDate: Date? = nil
    var initialContext: ContextNode? = nil

    @Query(sort: \ContextNode.sortOrder) private var allContexts: [ContextNode]

    @State private var title = ""
    @State private var selectedContext: ContextNode?
    @State private var showContextPicker = false

    init(assignedDate: Date? = nil, initialContext: ContextNode? = nil) {
        self.assignedDate = assignedDate
        self.initialContext = initialContext
        _selectedContext = State(initialValue: initialContext)
    }
    @FocusState private var isFocused: Bool

    private var recentContexts: [ContextNode] {
        let ids = RecentContextsManager.recentIDs
        let selectedID = selectedContext?.id
        return ids.compactMap { id in
            allContexts.first { $0.id == id }
        }
        .filter { $0.id != selectedID }
        .prefix(3)
        .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Large, Clean Input
                TextField(
                    assignedDate != nil ? "Add a task for today..." : "What needs to be done?",
                    text: $title,
                    axis: .vertical
                )
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .medium))
                    .lineLimit(1...)
                    .focused($isFocused)
                    .padding(.horizontal, 2)
                
                // 2. Context Pills (wrapping, no scroll)
                FlowLayout(spacing: 8) {
                    // Selected / default context
                    Button {
                        showContextPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: Theme.Icons.folder)
                                .font(.subheadline)
                            Text(selectedContext?.fullPath ?? "无关联上下文")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showContextPicker, arrowEdge: .bottom) {
                        ContextPickerView(selectedContext: $selectedContext)
                    }

                    // Recent Context Pills
                    ForEach(recentContexts, id: \.id) { ctx in
                        Button {
                            selectedContext = ctx
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: Theme.Icons.folder)
                                    .font(.subheadline)
                                Text(ctx.fullPath)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // 3. Date pill — visually separated from contexts
                if assignedDate != nil {
                    Divider()
                        .padding(.vertical, 2)
                    HStack(spacing: 6) {
                        Image(systemName: Theme.Icons.calendar)
                        Text("Today")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // 3. Bottom Action Bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .controlSize(.large)
                    
                    Spacer()
                    
                    Button("Add Task") { addTask() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(minWidth: 500, maxWidth: 500)
            .background(.background)
            .onAppear {
                isFocused = true
            }
            .navigationTitle("") // Hide default title
            .toolbar(.hidden, for: .windowToolbar) // Hide toolbar to use custom actions
        }
        // No fixed height — adapts to content
    }
    
    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let ctx = selectedContext {
            RecentContextsManager.record(ctx.id)
        }

        let newItem = Item(title: trimmedTitle, assignedDate: assignedDate, context: selectedContext)
        modelContext.insert(newItem)
        dismiss()
    }
}
