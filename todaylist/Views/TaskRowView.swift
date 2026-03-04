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
    var onStartTask: (() -> Void)? = nil

    // State for hover effect on action button
    @State private var isActionHovering = false
    @State private var isTimerHovering = false

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

    // Whether the task is paused (has been tracked but not currently in progress and not completed)
    private var isPaused: Bool {
        item.hasBeenTracked && !item.isInProgress && !item.isCompleted
    }

    var body: some View {
        HStack(alignment: .top) {
            // Checkbox with linear icon and animation
            Image(systemName: item.isCompleted ? Theme.Icons.taskComplete : Theme.Icons.taskIncomplete)
                .foregroundStyle(item.isCompleted ? completedIconColor : .secondary)
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

            VStack(alignment: .leading, spacing: Theme.Spacing.taskRowInternal) {
                Text(item.title)
                    .foregroundStyle(item.isCompleted ? Theme.Colors.completedText : Theme.Colors.primaryText)
                    .strikethrough(item.isCompleted)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                // Breadcrumb: only show in scheduled view (detail), hide in Inbox (sidebar)
                if isScheduled, let context = item.context {
                    Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                        .breadcrumbTagStyle()
                }

                // Show elapsed time for tracked tasks (in-progress: live; paused: static)
                if isToday && item.hasBeenTracked && !item.isCompleted {
                    if item.isInProgress, let startedAt = item.startedAt {
                        ElapsedTimeView(since: startedAt, accumulated: item.accumulatedDuration)
                    } else {
                        Text("⏱ \(ElapsedTimeView.formatDuration(item.accumulatedDuration))")
                            .font(Theme.Fonts.completionTime)
                            .foregroundStyle(Theme.Colors.completionTime)
                    }
                }

                // Show completion time below title for today's completed tasks
                if isToday && item.isCompleted, let completedAt = item.completedAt {
                    HStack(spacing: 4) {
                        Text("· \(Self.timeFormatter.string(from: completedAt))")
                        if item.hasBeenTracked, let duration = item.totalDuration {
                            Text("(\(ElapsedTimeView.formatDuration(duration)))")
                        }
                    }
                    .font(Theme.Fonts.completionTime)
                    .foregroundColor(Theme.Colors.completionTime)
                }
            }

            Spacer()

            // Timer play/pause button
            if isToday && !item.isCompleted, let onStartTask {
                Button(action: onStartTask) {
                    Image(systemName: item.isInProgress ? Theme.Icons.pauseTask : Theme.Icons.startTask)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(
                    item.isInProgress
                        ? Theme.Colors.todayAccent
                        : (isTimerHovering ? .secondary : Theme.Colors.mutedAction)
                )
                .opacity(item.isInProgress || isPaused || isTimerHovering ? 1 : 0)
                .onHover { hovering in
                    withAnimation(Theme.Animation.standard) {
                        isTimerHovering = hovering
                    }
                }
                .help(item.isInProgress ? "Pause Timer" : (isPaused ? "Resume Timer" : "Start Timer"))
            }

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
        .padding(.vertical, item.isInProgress ? 2 : 0)
        .padding(.horizontal, item.isInProgress ? 4 : 0)
        .background(
            item.isInProgress
                ? RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.todayAccent.opacity(0.06))
                : nil
        )
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: Theme.Icons.edit)
            }

            if isToday && !item.isCompleted, let onStartTask {
                Divider()
                if item.isInProgress {
                    Button(action: onStartTask) {
                        Label("Pause Timer", systemImage: Theme.Icons.pauseTask)
                    }
                } else if isPaused {
                    Button(action: onStartTask) {
                        Label("Resume Timer", systemImage: Theme.Icons.startTask)
                    }
                } else {
                    Button(action: onStartTask) {
                        Label("Start Timer", systemImage: Theme.Icons.startTask)
                    }
                }
                Divider()
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
