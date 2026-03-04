import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var assignedDate: Date? = nil

    @Query(sort: \ContextNode.sortOrder) private var allContexts: [ContextNode]

    @State private var title = ""
    @State private var selectedContext: ContextNode?
    @State private var showContextPicker = false
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
                TextField(assignedDate != nil ? "Add a task for today..." : "What needs to be done?", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .medium))
                    .focused($isFocused)
                    .onSubmit { addTask() }
                    .padding(.horizontal, 2)
                
                // 2. Metadata Row (Pills)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Context Pill
                        Button {
                            showContextPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: Theme.Icons.folder)
                                    .font(.subheadline)
                                Text(selectedContext?.fullPath ?? "Inbox")
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
                                    Text(ctx.name)
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

                        // Date Pill (if applicable)
                        if assignedDate != nil {
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
                    }
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
            .frame(width: 500, height: 220)
            .background(.background)
            .onAppear {
                isFocused = true
            }
            .navigationTitle("") // Hide default title
            .toolbar(.hidden, for: .windowToolbar) // Hide toolbar to use custom actions
        }
        .frame(height: 220) // Compact height since we use popover now
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
