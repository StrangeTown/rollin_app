//
//  DailyLogView.swift
//  todaylist
//

import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logManager = DailyLogManager.shared

    // Today's tasks for optional linking
    let todayItems: [Item]

    @State private var inputText: String = ""
    @State private var selectedTask: Item? = nil
    @FocusState private var isInputFocused: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HStack {
                Text("今日流水账")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: Theme.Icons.dismiss)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)

            Divider()

            // MARK: Input Area
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("现在在干嘛...", text: $inputText)
                        .textFieldStyle(.plain)
                        .focused($isInputFocused)
                        .onSubmit { submitEntry() }

                    Button(action: submitEntry) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Theme.Colors.todayAccent)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.Colors.timelineTagBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))

                // Optional task link - inline chips
                if !todayItems.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("关联任务")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        FlowLayout(spacing: 6) {
                            // "不关联" chip
                            TaskChip(
                                title: "不关联",
                                isSelected: selectedTask == nil,
                                action: { selectedTask = nil }
                            )
                            ForEach(todayItems) { item in
                                TaskChip(
                                    title: item.title,
                                    isSelected: selectedTask == item,
                                    action: { selectedTask = (selectedTask == item) ? nil : item }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // MARK: Log Timeline
            if logManager.entries.isEmpty {
                ContentUnavailableView(
                    "暂无记录",
                    systemImage: "note.text",
                    description: Text("记录一下现在在干什么吧")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(logManager.entries.reversed()) { entry in
                            DailyLogEntryRow(
                                entry: entry,
                                timeFormatter: Self.timeFormatter,
                                onDelete: { logManager.deleteEntry(id: entry.id) }
                            )
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .frame(width: 380, height: 620)
        .onAppear {
            logManager.loadAndValidate()
            isInputFocused = true
        }
    }

    private func submitEntry() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let entry = DailyLogEntry(
            content: text,
            linkedTaskId: selectedTask.map { String(describing: $0.id) },
            linkedTaskTitle: selectedTask?.title
        )
        logManager.addEntry(entry)
        inputText = ""
        selectedTask = nil
    }
}

// MARK: - Entry Row

struct DailyLogEntryRow: View {
    let entry: DailyLogEntry
    let timeFormatter: DateFormatter
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(Theme.Colors.todayAccent.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .padding(.top, 4)
                Rectangle()
                    .fill(Theme.Colors.todayAccent.opacity(0.15))
                    .frame(width: 1.5)
            }

            // Content: time + text in one line, optional tag below
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(timeFormatter.string(from: entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(Theme.Colors.timelineTimestamp)
                    Text(entry.content)
                        .font(.callout)
                        .foregroundColor(Theme.Colors.timelineText)
                }

                if let taskTitle = entry.linkedTaskTitle {
                    Text(taskTitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.timelineTimestamp)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.timelineTagBackground)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 12)

            Spacer()

            // Delete button on hover
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}

#Preview {
    DailyLogView(todayItems: [])
        .modelContainer(for: Item.self, inMemory: true)
}

// MARK: - Task Chip

struct TaskChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Theme.Colors.todayAccent : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(isSelected
                              ? Theme.Colors.todayAccent.opacity(0.12)
                              : Theme.Colors.timelineTagBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .strokeBorder(isSelected
                                              ? Theme.Colors.todayAccent.opacity(0.4)
                                              : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        y += rowHeight
        return CGSize(width: maxWidth, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.maxX
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
