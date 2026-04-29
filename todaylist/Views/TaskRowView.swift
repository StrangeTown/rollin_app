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
    let showContextTag: Bool
    var onToggleTodayPriority: (() -> Void)? = nil

    // State for hover effect on action button
    @State private var isActionHovering = false
    @State private var isCheckboxHovering = false
    @State private var isRowHovering = false

    // State for completion animation
    @State private var completionScale: CGFloat = 1.0

    // Time formatter for completion time (e.g. "20:12")
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // Completed icon color: blue only for Today, gray for past days
    private var completedIconColor: Color {
        isToday ? Theme.Colors.todayAccent : Theme.Colors.completedText
    }

    private var isPrioritizedForToday: Bool {
        guard isToday,
              let priorityDate = item.todayPriorityDate,
              let assignedDate = item.assignedDate else {
            return false
        }
        return Calendar.current.isDate(priorityDate, inSameDayAs: assignedDate)
    }

    private var titleColor: Color {
        if isPrioritizedForToday {
            return Theme.Colors.todayPriorityTitle
        }
        return item.isCompleted ? Theme.Colors.completedText : Theme.Colors.primaryText
    }

    var body: some View {
        HStack(alignment: .top) {
            // Checkbox with linear icon and animation
            Image(systemName: item.isCompleted ? Theme.Icons.taskComplete : Theme.Icons.taskIncomplete)
                .foregroundStyle(item.isCompleted ? completedIconColor : (isToday ? Theme.Colors.todayIncomplete : .secondary))
                .scaleEffect(completionScale)
                .contentShape(Rectangle().size(width: 24, height: 24))
                .onTapGesture {
                    // Animate completion only for Today tasks
                    if !item.isCompleted && isToday {
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
                .onHover { hovering in
                    if hovering, !isCheckboxHovering {
                        NSCursor.pointingHand.push()
                        isCheckboxHovering = true
                    } else if !hovering, isCheckboxHovering {
                        NSCursor.pop()
                        isCheckboxHovering = false
                    }
                }
                .onDisappear {
                    if isCheckboxHovering {
                        NSCursor.pop()
                        isCheckboxHovering = false
                    }
                }

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: Theme.Spacing.taskRowInternal) {
                    Text(item.title)
                        .foregroundStyle(titleColor)
                        .strikethrough(item.isCompleted)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if (isScheduled || showContextTag), let context = item.context {
                        Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                            .breadcrumbTagStyle()
                    }

                    // Show completion time below title for today's completed tasks
                    if isToday && item.isCompleted, let completedAt = item.completedAt {
                        HStack(spacing: 4) {
                            Text("· \(Self.timeFormatter.string(from: completedAt))")
                        }
                        .font(Theme.Fonts.completionTime)
                        .foregroundColor(Theme.Colors.completionTime)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2, perform: onEdit)

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
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(
                    isRowHovering ? Theme.Colors.hoverBackground : Color.clear
                )
        )
        .onHover { hovering in
            withAnimation(Theme.Animation.standard) {
                isRowHovering = hovering
            }
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: Theme.Icons.edit)
            }

            if isToday, let onToggleTodayPriority {
                Button(action: onToggleTodayPriority) {
                    Label(
                        isPrioritizedForToday ? "取消优先" : "优先",
                        systemImage: isPrioritizedForToday ? Theme.Icons.priorityOff : Theme.Icons.priority
                    )
                }
            }

            if !isScheduled || (isToday && !item.isCompleted) {
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
