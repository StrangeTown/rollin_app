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

    // MARK: - Time Period Helpers

    private static let calendar = Calendar.current

    private static func hour(of entry: DailyLogEntry) -> Int {
        calendar.component(.hour, from: entry.timestamp)
    }

    private var morningEntries: [DailyLogEntry] {
        logManager.entries.filter { Self.hour(of: $0) < 12 }
    }

    private var afternoonEntries: [DailyLogEntry] {
        logManager.entries.filter { let h = Self.hour(of: $0); return h >= 12 && h < 18 }
    }

    private var eveningEntries: [DailyLogEntry] {
        logManager.entries.filter { Self.hour(of: $0) >= 18 }
    }

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
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            // MARK: Three-column Timeline
            HStack(alignment: .top, spacing: 0) {
                LogTimeColumn(
                    title: "上午",
                    subtitle: "00:00 – 12:00",
                    entries: morningEntries,
                    timeFormatter: Self.timeFormatter,
                    connectorHeightFn: Self.connectorHeight,
                    onDelete: { id in logManager.deleteEntry(id: id) }
                )
                Divider()
                LogTimeColumn(
                    title: "下午",
                    subtitle: "12:00 – 18:00",
                    entries: afternoonEntries,
                    timeFormatter: Self.timeFormatter,
                    connectorHeightFn: Self.connectorHeight,
                    onDelete: { id in logManager.deleteEntry(id: id) }
                )
                Divider()
                LogTimeColumn(
                    title: "晚上",
                    subtitle: "18:00 – 24:00",
                    entries: eveningEntries,
                    timeFormatter: Self.timeFormatter,
                    connectorHeightFn: Self.connectorHeight,
                    onDelete: { id in logManager.deleteEntry(id: id) }
                )
            }
            .frame(maxHeight: .infinity)

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
        }
        .frame(width: 660, height: 520)
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

    /// Maps time gap between two entries to a connector line height.
    /// Uses log-scale buckets: small gaps → short line, large gaps → tall line.
    private static func connectorHeight(from entry: DailyLogEntry, to next: DailyLogEntry?) -> CGFloat {
        guard let next = next else { return 6 } // last item
        let minutes = next.timestamp.timeIntervalSince(entry.timestamp) / 60
        switch minutes {
        case ..<2:   return 6
        case ..<5:   return 10
        case ..<15:  return 16
        case ..<30:  return 22
        case ..<45:  return 28
        default:     return 34
        }
    }
}

// MARK: - Time Period Column

struct LogTimeColumn: View {
    let title: String
    let subtitle: String
    let entries: [DailyLogEntry]
    let timeFormatter: DateFormatter
    let connectorHeightFn: (DailyLogEntry, DailyLogEntry?) -> CGFloat
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.Colors.primaryText)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            if entries.isEmpty {
                Spacer()
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            let next: DailyLogEntry? = index + 1 < entries.count ? entries[index + 1] : nil
                            DailyLogEntryRow(
                                entry: entry,
                                connectorHeight: connectorHeightFn(entry, next),
                                timeFormatter: timeFormatter,
                                onDelete: { onDelete(entry.id) }
                            )
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Entry Row

struct DailyLogEntryRow: View {
    let entry: DailyLogEntry
    let connectorHeight: CGFloat
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
                    .frame(width: 1.5, height: connectorHeight)
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
            .padding(.bottom, connectorHeight)

            Spacer()

            // Delete button - always in layout, visible only on hover
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .opacity(isHovering ? 1 : 0)
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
