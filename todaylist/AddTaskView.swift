import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var assignedDate: Date? = nil
    
    @State private var title = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if assignedDate != nil {
                    Label("For Today", systemImage: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.leading, 4)
                        .padding(.bottom, 4)
                }
                
                TextField(assignedDate != nil ? "Add a task for today..." : "What needs to be done?", text: $title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .padding()
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .onSubmit {
                        addTask()
                    }
            }
            .padding()
            .navigationTitle(assignedDate != nil ? "Add to Today" : "New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(width: 400, height: assignedDate != nil ? 130 : 100)
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newItem = Item(title: trimmedTitle, assignedDate: assignedDate)
        modelContext.insert(newItem)
        dismiss()
    }
}
