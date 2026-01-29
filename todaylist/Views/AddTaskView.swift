import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var assignedDate: Date? = nil
    
    @State private var title = ""
    @State private var selectedContext: ContextNode?
    @State private var showContextPicker = false
    @FocusState private var isFocused: Bool
    
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
                HStack(spacing: 12) {
                    // Context Pill
                    Button {
                        showContextPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: Theme.Icons.folder)
                                .font(.subheadline)
                            Text(selectedContext?.name ?? "Inbox")
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
        
        let newItem = Item(title: trimmedTitle, assignedDate: assignedDate, context: selectedContext)
        modelContext.insert(newItem)
        dismiss()
    }
}
