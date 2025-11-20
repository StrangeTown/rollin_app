import SwiftUI

struct TaskRowView: View {
    let item: Item
    let onToggleCompletion: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let isScheduled: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    onToggleCompletion()
                }
            Text(item.title)
                .strikethrough(item.isCompleted)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: onMove) {
                Label(isScheduled ? "Remove from Today" : "Today", 
                      systemImage: isScheduled ? "xmark.circle" : "sun.max")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help(isScheduled ? "Remove from Today" : "Move to Today")
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
