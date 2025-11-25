import SwiftUI

struct TaskRowView: View {
    let item: Item
    let onToggleCompletion: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let isScheduled: Bool
    let isToday: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onToggleCompletion()
                }
            Text(item.title)
                .foregroundColor(item.isCompleted ? .secondary.opacity(0.7) : .primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
