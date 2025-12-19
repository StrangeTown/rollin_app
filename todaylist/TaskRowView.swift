import SwiftUI
import AppKit

struct TaskRowView: View {
    let item: Item
    let onToggleCompletion: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let isScheduled: Bool
    let isToday: Bool
    
    @FocusState private var isFocused: Bool
    
    // Time formatter for completion time (e.g. "20:12")
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onToggleCompletion()
                }
            
            VStack(alignment: .leading, spacing: 2) {
                TextField("Task Title", text: Binding(
                    get: { item.title },
                    set: { item.title = $0 }
                ), axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(item.isCompleted ? .secondary.opacity(0.5) : .primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                
                if let context = item.context {
                    Text(context.fullPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Show completion time below title for today's completed tasks
                if isToday && item.isCompleted, let completedAt = item.completedAt {
                    Text("· \(Self.timeFormatter.string(from: completedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            
            Spacer()
            
            if !isScheduled || isToday {
                Button(action: onMove) {
                    Label(isScheduled ? "Remove from Today" : "Today", 
                          systemImage: isScheduled ? "xmark.circle" : "sun.max")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help(isScheduled ? "Remove from Today" : "Move to Today")
            }
        }
        .contextMenu {
            if !isScheduled || isToday {
                Button(action: onMove) {
                    Label(isScheduled ? "Move to Inbox" : "Move to Today", 
                          systemImage: isScheduled ? "tray" : "sun.max")
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
