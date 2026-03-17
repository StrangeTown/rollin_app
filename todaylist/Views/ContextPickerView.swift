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

    private var displayedContexts: [FlatContextNode] {
        if searchText.isEmpty {
            let roots = allContexts.filter { $0.parent == nil }
            return flatten(roots)
        } else {
            return allContexts
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .map { FlatContextNode(node: $0, level: 0) }
        }
    }

    private func flatten(_ nodes: [ContextNode], level: Int = 0) -> [FlatContextNode] {
        var result: [FlatContextNode] = []
        for node in nodes {
            result.append(FlatContextNode(node: node, level: level))
            if let children = node.children, !children.isEmpty, expandedNodes.contains(node.id) {
                let sortedChildren = children.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
                result.append(contentsOf: flatten(sortedChildren, level: level + 1))
            }
        }
        return result
    }
    
    struct FlatContextNode: Identifiable {
        var id: UUID { node.id }
        let node: ContextNode
        let level: Int
    }
    
    var body: some View {
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
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search contexts...")
        .frame(minWidth: 260, minHeight: 320)
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
            if let children = item.node.children, !children.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        toggleExpansion(for: item.node)
                    }
                } label: {
                    Image(systemName: expandedNodes.contains(item.node.id) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Spacer().frame(width: 32)
            }

            ContextPickerRow(item: item, isSelected: selectedContext == item.node)
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
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
                .frame(width: CGFloat(item.level) * 14)
            
            Image(systemName: (item.node.children?.isEmpty == false) ? "circle.fill" : "circle")
                .foregroundStyle(.secondary)
                .font(.system(size: 8))
            
            Text(item.node.name)
                .foregroundStyle(.primary)
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
}
