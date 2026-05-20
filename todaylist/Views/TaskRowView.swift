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
    var onStartFocus: (() -> Void)? = nil
    var isCurrentlyFocused: Bool = false
    var onAddSubtask: (() -> Void)? = nil

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
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(TitleLinkifier.attributedTitle(
                            item.title,
                            isCompleted: item.isCompleted,
                            baseColor: titleColor
                        ))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)

                        if isToday, !item.subtasks.isEmpty {
                            let done = item.subtasks.filter { $0.isCompleted }.count
                            Text("\(done)/\(item.subtasks.count)")
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }

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
            // 最常用的两项放在最上面单独成组
            let canAddSubtask = isToday && onAddSubtask != nil
            let hasTopGroup = canAddSubtask || (isToday && onToggleTodayPriority != nil) || onStartFocus != nil

            if canAddSubtask, let onAddSubtask {
                Button(action: onAddSubtask) {
                    Label("添加子任务", systemImage: Theme.Icons.add)
                }
            }

            if isToday, let onToggleTodayPriority {
                Button(action: onToggleTodayPriority) {
                    Label(
                        isPrioritizedForToday ? "取消优先" : "优先",
                        systemImage: isPrioritizedForToday ? Theme.Icons.priorityOff : Theme.Icons.priority
                    )
                }
            }

            if let onStartFocus {
                Button(action: onStartFocus) {
                    Label(
                        isCurrentlyFocused ? "查看专注计时" : "开始专注",
                        systemImage: Theme.Icons.focus
                    )
                }
            }

            if hasTopGroup {
                Divider()
            }

            Button(action: onEdit) {
                Label("Edit", systemImage: Theme.Icons.edit)
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

// MARK: - Subtask Row

/// 子任务行：仅在 Today 视图下显示。左缩进、轻量样式；只支持「勾选完成」+「右键删除」。
/// 子任务是 Codable 值类型，所以这里只展示，状态变更通过回调由父视图操作 `parent.subtasks` 数组。
struct SubtaskRow: View {
    let subtask: Subtask
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var isCheckboxHovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: subtask.isCompleted ? Theme.Icons.taskComplete : Theme.Icons.taskIncomplete)
                .font(.system(size: 12))
                .foregroundStyle(subtask.isCompleted ? Theme.Colors.completedText : .secondary)
                .contentShape(Rectangle().size(width: 20, height: 20))
                .onTapGesture { onToggleCompletion() }
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

            Text(subtask.title)
                .font(.callout)
                .foregroundStyle(subtask.isCompleted ? Theme.Colors.completedText : Theme.Colors.primaryText)
                .strikethrough(subtask.isCompleted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .padding(.leading, Theme.Spacing.childIndent)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(isHovering ? Theme.Colors.hoverBackground : Color.clear)
        )
        .onHover { hovering in
            withAnimation(Theme.Animation.standard) { isHovering = hovering }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: Theme.Icons.delete)
            }
        }
    }
}

// MARK: - New-subtask inline input

/// 子任务的行内输入框：回车保存并自动开启下一行；空回车 / Esc / 失焦清空 → 收起。
struct NewSubtaskInputRow: View {
    let parent: Item
    /// 当用户表示已完成添加（空回车 / Esc / 失焦清空时）由调用方收起输入框。
    let onDismiss: () -> Void

    @State private var draft: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: Theme.Icons.taskIncomplete)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            TextField("添加子任务，回车保存", text: $draft)
                .textFieldStyle(.plain)
                .font(.callout)
                .focused($isFocused)
                .onSubmit { commit() }
                .onExitCommand { onDismiss() }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .padding(.leading, Theme.Spacing.childIndent)
        .onAppear { isFocused = true }
        .onChange(of: isFocused) { _, focused in
            // 失去焦点时若输入框为空，自动收起。
            if !focused && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                onDismiss()
            }
        }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onDismiss()
            return
        }
        parent.subtasks.append(Subtask(title: trimmed))
        draft = ""
        isFocused = true
    }
}
