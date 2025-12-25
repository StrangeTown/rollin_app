import SwiftUI
import AppKit

struct TaskRowView: View {
    let item: Item
    let onToggleCompletion: () -> Void
    let onMove: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let isScheduled: Bool
    let isToday: Bool
    
    // State for hover effect on action button
    @State private var isActionHovering = false
    
    // State for completion animation
    @State private var completionScale: CGFloat = 1.0
    
    // Time formatter for completion time (e.g. "20:12")
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top) {
            // Checkbox with linear icon and animation
            Image(systemName: item.isCompleted ? Theme.Icons.taskComplete : Theme.Icons.taskIncomplete)
                .foregroundStyle(item.isCompleted ? Theme.Colors.todayAccent : .secondary)
                .scaleEffect(completionScale)
                .contentShape(Rectangle().size(width: 24, height: 24))
                .onTapGesture {
                    // Animate completion
                    if !item.isCompleted {
                        withAnimation(Theme.Animation.completionBounce) {
                            completionScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(Theme.Animation.completionBounce) {
                                completionScale = 1.0
                            }
                        }
                    }
                    onToggleCompletion()
                }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.taskRowInternal) {
                Text(item.title)
                    .foregroundStyle(item.isCompleted ? Theme.Colors.completedText : Color.primary)
                    .strikethrough(item.isCompleted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                // Breadcrumb with capsule tag style
                if let context = item.context {
                    Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                        .breadcrumbTagStyle()
                }
                
                // Show completion time below title for today's completed tasks
                if isToday && item.isCompleted, let completedAt = item.completedAt {
                    Text("· \(Self.timeFormatter.string(from: completedAt))")
                        .font(Theme.Fonts.completionTime)
                        .foregroundColor(Theme.Colors.completionTime)
                }
            }
            
            Spacer()
            
            // Action button with hover effect
            if !isScheduled || isToday {
                Button(action: onMove) {
                    Label(isScheduled ? "Remove from Today" : "Today", 
                          systemImage: isScheduled ? Theme.Icons.removeFromToday : Theme.Icons.moveToToday)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(isActionHovering ? .secondary : Theme.Colors.mutedAction)
                .onHover { hovering in
                    withAnimation(Theme.Animation.standard) {
                        isActionHovering = hovering
                    }
                }
                .help(isScheduled ? "Remove from Today" : "Move to Today")
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: Theme.Icons.edit)
            }
            
            if !isScheduled || isToday {
                Button(action: onMove) {
                    Label(isScheduled ? "Move to Inbox" : "Move to Today", 
                          systemImage: isScheduled ? Theme.Icons.moveToInbox : Theme.Icons.moveToToday)
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: Theme.Icons.delete)
            }
        }
    }
}
