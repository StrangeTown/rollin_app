import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var assignedDate: Date? = nil
    
    @State private var title = ""
    @State private var selectedContext: ContextNode?
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
                
                HStack {
                    Text("Context:")
                        .foregroundStyle(.secondary)
                    NavigationLink {
                        ContextPickerView(selectedContext: $selectedContext)
                    } label: {
                        HStack {
                            if let context = selectedContext {
                                Text(context.fullPath)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            } else {
                                Text("None")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(4)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
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
            .frame(width: 400)
            .frame(minHeight: assignedDate != nil ? 200 : 170)
            .fixedSize(horizontal: true, vertical: false)
            .onAppear {
                isFocused = true
            }
        }
        .frame(height: 400) // Give the window enough room for navigation
    }
    
    private func addTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newItem = Item(title: trimmedTitle, assignedDate: assignedDate, context: selectedContext)
        modelContext.insert(newItem)
        dismiss()
    }
}
