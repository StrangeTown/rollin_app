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
    
    // Display text with optional completion time for today's completed tasks
    private var displayTitle: String {
        if isToday && item.isCompleted, let completedAt = item.completedAt {
            return "\(item.title) · \(Self.timeFormatter.string(from: completedAt))"
        }
        return item.title
    }
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onToggleCompletion()
                }
            
            TextField("Task Title", text: Binding(
                get: { displayTitle },
                set: { newValue in
                    // Remove the completion time suffix when editing
                    if isToday && item.isCompleted, let completedAt = item.completedAt {
                        let suffix = " · \(Self.timeFormatter.string(from: completedAt))"
                        if newValue.hasSuffix(suffix) {
                            item.title = String(newValue.dropLast(suffix.count))
                        } else {
                            item.title = newValue
                        }
                    } else {
                        item.title = newValue
                    }
                }
            ), axis: .vertical)
            .textFieldStyle(.plain)
            .foregroundColor(item.isCompleted ? .secondary.opacity(0.5) : .primary)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            
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
