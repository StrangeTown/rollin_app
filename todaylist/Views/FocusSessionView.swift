//
//  FocusSessionView.swift
//  todaylist
//
//  独立的专注计时功能。计时仅存在于 @State 中，不持久化、与任务数据解耦。
//  唯一会写库的副作用是「结束计时（完成任务）」时把任务标记为已完成。
//

import SwiftUI
import SwiftData

struct FocusSessionView: View {
    /// 关闭回调。在 inspector 场景下 `@Environment(\.dismiss)` 无法关闭 inspector，
    /// 由调用方把 `isPresented` 置为 false。
    var onClose: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext

    // 拉取所有有 assignedDate 的任务，再在内存中按今天 + 未完成过滤
    @Query(filter: #Predicate<Item> { $0.assignedDate != nil })
    private var scheduledItems: [Item]

    // MARK: - Local State (临时变量，关闭即丢弃)
    @State private var selectedItem: Item?
    @State private var startedAt: Date?
    @State private var endedAt: Date?

    private var isRunning: Bool {
        startedAt != nil && endedAt == nil
    }

    private var isEnded: Bool {
        endedAt != nil
    }

    private var todayUnfinishedItems: [Item] {
        let calendar = Calendar.current
        let today = Date()
        return scheduledItems
            .filter { item in
                guard let date = item.assignedDate else { return false }
                return !item.isCompleted && calendar.isDate(date, inSameDayAs: today)
            }
            .sorted { ($0.timestamp) > ($1.timestamp) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Group {
                if let item = selectedItem {
                    if isEnded, let started = startedAt, let ended = endedAt {
                        endedView(item: item, elapsed: ended.timeIntervalSince(started))
                    } else if let started = startedAt {
                        runningView(item: item, since: started)
                    }
                } else {
                    pickView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("专注计时")
                .font(.headline)
            Spacer()
            Button(action: { onClose?() }) {
                Image(systemName: Theme.Icons.dismiss)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("关闭")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Pick Stage

    @ViewBuilder
    private var pickView: some View {
        if todayUnfinishedItems.isEmpty {
            ContentUnavailableView(
                "今天没有未完成任务",
                systemImage: Theme.Icons.emptyTimeline,
                description: Text("先把任务加到今天，再来专注。")
            )
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("选一个专注任务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(todayUnfinishedItems) { item in
                            FocusItemRow(item: item) {
                                startSession(with: item)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Running Stage

    private func runningView(item: Item, since started: Date) -> some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundStyle(Theme.Colors.primaryText)
                if let context = item.context {
                    Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            TimelineView(.periodic(from: started, by: 1)) { context in
                Text(Self.formatElapsed(context.date.timeIntervalSince(started)))
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.todayAccent)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { onClose?() }) {
                    Text("关闭")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: { endSession() }) {
                    Text("结束计时（完成任务）")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Ended Stage

    private func endedView(item: Item, elapsed: TimeInterval) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: Theme.Icons.taskComplete)
                .font(.system(size: 44))
                .foregroundStyle(Theme.Colors.todayAccent)

            VStack(spacing: 6) {
                Text("已完成")
                    .font(.headline)
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }

            Text(Self.formatElapsed(elapsed))
                .font(.system(size: 40, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.primaryText)

            Spacer()

            HStack(spacing: 12) {
                Button(action: { onClose?() }) {
                    Text("关闭")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: { resetForAnother() }) {
                    Text("再来一个")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Actions

    private func startSession(with item: Item) {
        selectedItem = item
        startedAt = Date()
        endedAt = nil
    }

    private func endSession() {
        guard let item = selectedItem, isRunning else { return }
        withAnimation {
            item.isCompleted = true
            item.completedAt = Date()
        }
        endedAt = Date()
    }

    private func resetForAnother() {
        selectedItem = nil
        startedAt = nil
        endedAt = nil
    }

    // MARK: - Formatting

    private static func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Item Row

private struct FocusItemRow: View {
    let item: Item
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: Theme.Icons.taskIncomplete)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .foregroundStyle(Theme.Colors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let context = item.context {
                        Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                            .breadcrumbTagStyle()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isHovering ? Theme.Colors.hoverBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.standard) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    FocusSessionView()
        .modelContainer(for: Item.self, inMemory: true)
}
