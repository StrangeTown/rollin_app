//
//  ContextPickerView.swift
//  todaylist
//
//  Created by GitHub Copilot on 2025/12/19.
//

import SwiftUI
import SwiftData

struct ContextPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ContextNode.sortOrder)
    private var allContexts: [ContextNode]
    
    @Binding var selectedContext: ContextNode?
    @State private var searchText = ""
    @State private var expandedNodes: Set<UUID> = []
    @FocusState private var isSearchFieldFocused: Bool

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var matchedNodeIDs: Set<UUID> {
        guard isSearching else { return [] }
        let keyword = normalizedSearchText
        return Set(
            allContexts.compactMap { node in
                (node.name.localizedCaseInsensitiveContains(keyword) ||
                 node.fullPath.localizedCaseInsensitiveContains(keyword)) ? node.id : nil
            }
        )
    }

    private var visibleNodeIDs: Set<UUID> {
        guard isSearching else { return Set(allContexts.map(\.id)) }
        var ids = matchedNodeIDs
        for node in allContexts where matchedNodeIDs.contains(node.id) {
            var parent = node.parent
            while let current = parent {
                ids.insert(current.id)
                parent = current.parent
            }
        }
        return ids
    }

    private var autoExpandedNodeIDs: Set<UUID> {
        guard isSearching else { return [] }
        var expanded: Set<UUID> = []
        for node in allContexts where matchedNodeIDs.contains(node.id) {
            var parent = node.parent
            while let current = parent {
                expanded.insert(current.id)
                parent = current.parent
            }
        }
        return expanded
    }

    private var displayedContexts: [FlatContextNode] {
        let roots = allContexts.filter { $0.parent == nil }
        if isSearching {
            return flattenSearch(
                roots,
                visibleNodeIDs: visibleNodeIDs,
                autoExpandedNodeIDs: autoExpandedNodeIDs,
                matchedNodeIDs: matchedNodeIDs
            )
        }
        return flattenRegular(roots)
    }

    private func flattenRegular(_ nodes: [ContextNode], level: Int = 0) -> [FlatContextNode] {
        var result: [FlatContextNode] = []
        let sortedNodes = nodes.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
        for node in sortedNodes {
            let children = (node.children ?? []).sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
            let hasChildren = !children.isEmpty
            let isExpanded = expandedNodes.contains(node.id)
            result.append(
                FlatContextNode(
                    node: node,
                    level: level,
                    isMatched: false,
                    hasVisibleChildren: hasChildren,
                    isExpanded: isExpanded
                )
            )
            if hasChildren, isExpanded {
                result.append(contentsOf: flattenRegular(children, level: level + 1))
            }
        }
        return result
    }

    private func flattenSearch(
        _ nodes: [ContextNode],
        level: Int = 0,
        visibleNodeIDs: Set<UUID>,
        autoExpandedNodeIDs: Set<UUID>,
        matchedNodeIDs: Set<UUID>
    ) -> [FlatContextNode] {
        var result: [FlatContextNode] = []
        let sortedNodes = nodes.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
        for node in sortedNodes where visibleNodeIDs.contains(node.id) {
            let children = (node.children ?? [])
                .sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
                .filter { visibleNodeIDs.contains($0.id) }
            let hasChildren = !children.isEmpty
            let isExpanded = autoExpandedNodeIDs.contains(node.id)
            result.append(
                FlatContextNode(
                    node: node,
                    level: level,
                    isMatched: matchedNodeIDs.contains(node.id),
                    hasVisibleChildren: hasChildren,
                    isExpanded: isExpanded
                )
            )
            if hasChildren, isExpanded {
                result.append(
                    contentsOf: flattenSearch(
                        children,
                        level: level + 1,
                        visibleNodeIDs: visibleNodeIDs,
                        autoExpandedNodeIDs: autoExpandedNodeIDs,
                        matchedNodeIDs: matchedNodeIDs
                    )
                )
            }
        }
        return result
    }

    struct FlatContextNode: Identifiable {
        var id: UUID { node.id }
        let node: ContextNode
        let level: Int
        let isMatched: Bool
        let hasVisibleChildren: Bool
        let isExpanded: Bool
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("过滤上下文", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 10)
            .padding(.top, 10)

            List {
                Section {
                    noContextRow
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                }

                Section {
                    if displayedContexts.isEmpty {
                        emptyResultRow
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
                    } else {
                        ForEach(displayedContexts) { item in
                            contextRow(item)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        }
                    }
                } header: {
                    Text("上下文")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
        }
        .frame(minWidth: 260, minHeight: 320)
        .onAppear {
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
    }

    private var noContextRow: some View {
        Button {
            selectedContext = nil
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
                Text("无关联上下文")
                Spacer()
                if selectedContext == nil {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var emptyResultRow: some View {
        VStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            Text("未找到匹配的上下文")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func contextRow(_ item: FlatContextNode) -> some View {
        HStack(spacing: 0) {
            if item.hasVisibleChildren {
                if isSearching {
                    Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            toggleExpansion(for: item.node)
                        }
                    } label: {
                        Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Spacer().frame(width: 32)
            }

            ContextPickerRow(
                item: item,
                isSelected: selectedContext == item.node,
                highlightKeyword: normalizedSearchText
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(selectedContext == item.node ? Color.accentColor.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture {
            selectedContext = item.node
            dismiss()
        }
    }

    private func toggleExpansion(for node: ContextNode) {
        if expandedNodes.contains(node.id) {
            expandedNodes.remove(node.id)
        } else {
            expandedNodes.insert(node.id)
        }
    }
}

struct ContextPickerRow: View {
    let item: ContextPickerView.FlatContextNode
    let isSelected: Bool
    let highlightKeyword: String

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
                .frame(width: CGFloat(item.level) * 14)

            Image(systemName: item.hasVisibleChildren ? "circle.fill" : "circle")
                .foregroundStyle(.secondary)
                .font(.system(size: 8))

            highlightedText(item.node.name)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 6)
    }

    private func highlightedText(_ text: String) -> Text {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .primary

        guard item.isMatched, !highlightKeyword.isEmpty else {
            return Text(attributed)
        }

        var searchStart = attributed.startIndex
        while let range = attributed[searchStart...].range(
            of: highlightKeyword,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) {
            attributed[range].foregroundColor = .accentColor
            searchStart = range.upperBound
        }

        return Text(attributed)
    }
}
