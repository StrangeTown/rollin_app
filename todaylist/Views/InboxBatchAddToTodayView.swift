import SwiftUI
import SwiftData

struct InboxBatchAddToTodayView: View {
    private enum ChipSelectionState {
        case none
        case partial
        case all
    }

    @Environment(\.dismiss) private var dismiss

    let items: [Item]
    let onApply: ([Item]) -> Void

    @State private var selectedItemIDs: Set<PersistentIdentifier> = []

    private var availableContexts: [ContextNode] {
        var unique: [UUID: ContextNode] = [:]
        for context in items.compactMap(\.context) {
            unique[context.id] = context
        }
        return Array(unique.values).sorted { $0.fullPath.localizedStandardCompare($1.fullPath) == .orderedAscending }
    }

    private var allItemIDs: Set<PersistentIdentifier> {
        Set(items.map(\.persistentModelID))
    }

    private var contextItemIDsByContextID: [UUID: Set<PersistentIdentifier>] {
        var result: [UUID: Set<PersistentIdentifier>] = [:]
        for item in items {
            guard let contextID = item.context?.id else { continue }
            result[contextID, default: []].insert(item.persistentModelID)
        }
        return result
    }

    private var isAllSelected: Bool {
        !items.isEmpty && selectedItemIDs == allItemIDs
    }

    private var selectedCount: Int {
        selectedItemIDs.count
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("批量添加到今天")
                    .font(.headline)
                Spacer()
                Text("已选 \(selectedCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            contextFilterBar

            if items.isEmpty {
                ContentUnavailableView("Inbox 为空", systemImage: "tray", description: Text("先添加一些任务到 Inbox。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(items) { item in
                        Button {
                            toggleSelection(for: item)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: selectedItemIDs.contains(item.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedItemIDs.contains(item.persistentModelID) ? Theme.Colors.todayAccent : .secondary)
                                    .padding(.top, 1)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)

                                    if let context = item.context {
                                        Text(context.fullPath.replacingOccurrences(of: " / ", with: " › "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }

            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("添加到今天") {
                    applySelection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItemIDs.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 560, minHeight: 420)
    }

    private var contextFilterBar: some View {
        FlowLayout(spacing: 8) {
            contextChip(
                title: "全选",
                selectionState: allSelectionState
            ) {
                toggleSelectAll()
            }

            ForEach(availableContexts, id: \.id) { context in
                contextChip(
                    title: context.fullPath,
                    selectionState: contextSelectionState(for: context.id)
                ) {
                    toggleContextSelection(contextID: context.id)
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var allSelectionState: ChipSelectionState {
        if isAllSelected { return .all }
        if selectedItemIDs.isEmpty { return .none }
        return .partial
    }

    private func contextSelectionState(for contextID: UUID) -> ChipSelectionState {
        guard let contextItemIDs = contextItemIDsByContextID[contextID], !contextItemIDs.isEmpty else {
            return .none
        }
        let selectedInContext = selectedItemIDs.intersection(contextItemIDs).count
        if selectedInContext == 0 { return .none }
        if selectedInContext == contextItemIDs.count { return .all }
        return .partial
    }

    private func contextChip(title: String, selectionState: ChipSelectionState, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(chipForeground(for: selectionState))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(chipBackground(for: selectionState))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func chipForeground(for state: ChipSelectionState) -> Color {
        switch state {
        case .all:
            return Theme.Colors.todayAccent
        case .partial:
            return Theme.Colors.todayAccent.opacity(0.8)
        case .none:
            return .secondary
        }
    }

    private func chipBackground(for state: ChipSelectionState) -> Color {
        switch state {
        case .all:
            return Theme.Colors.todayAccent.opacity(0.16)
        case .partial:
            return Theme.Colors.todayAccent.opacity(0.08)
        case .none:
            return Color.gray.opacity(0.12)
        }
    }

    private func toggleSelectAll() {
        if isAllSelected {
            selectedItemIDs.removeAll()
        } else {
            selectedItemIDs = allItemIDs
        }
    }

    private func toggleContextSelection(contextID: UUID) {
        guard let contextItemIDs = contextItemIDsByContextID[contextID], !contextItemIDs.isEmpty else {
            return
        }
        if contextItemIDs.isSubset(of: selectedItemIDs) {
            selectedItemIDs.subtract(contextItemIDs)
        } else {
            selectedItemIDs.formUnion(contextItemIDs)
        }
    }

    private func toggleSelection(for item: Item) {
        let id = item.persistentModelID
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func applySelection() {
        let selectedItems = items.filter { selectedItemIDs.contains($0.persistentModelID) }
        guard !selectedItems.isEmpty else { return }
        onApply(selectedItems)
        dismiss()
    }
}

