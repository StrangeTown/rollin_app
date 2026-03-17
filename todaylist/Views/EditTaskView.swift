import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    
    let item: Item
    
    @State private var title: String
    @State private var selectedContext: ContextNode?
    @State private var showContextPicker = false
    @FocusState private var isFocused: Bool
    
    init(item: Item) {
        self.item = item
        _title = State(initialValue: item.title)
        _selectedContext = State(initialValue: item.context)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Large, Clean Input
                TextField("Task name", text: $title, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .medium))
                    .lineLimit(1...)
                    .focused($isFocused)
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
                }
                
                Spacer()
                
                // 3. Bottom Action Bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .controlSize(.large)
                    
                    Spacer()
                    
                    Button("Save") { saveTask() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(minWidth: 500, minHeight: 200)
            .background(.background)
            .onAppear {
                isFocused = true
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .windowToolbar)
        }
    }
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        withAnimation {
            item.title = trimmedTitle
            item.context = selectedContext
        }
        dismiss()
    }
}
