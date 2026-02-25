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
            Button {
                selectedContext = nil
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                    Text("None")
                    Spacer()
                    if selectedContext == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            
            Divider()
            
            ForEach(displayedContexts) { item in
                HStack(spacing: 0) {
                    // Expand/collapse toggle for parent nodes
                    if let children = item.node.children, !children.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if expandedNodes.contains(item.node.id) {
                                    expandedNodes.remove(item.node.id)
                                } else {
                                    expandedNodes.insert(item.node.id)
                                }
                            }
                        } label: {
                            Image(systemName: expandedNodes.contains(item.node.id) ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer().frame(width: 20)
                    }

                    ContextPickerRow(item: item, isSelected: selectedContext == item.node)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedContext = item.node
                    dismiss()
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search contexts...")
        .frame(minWidth: 250, minHeight: 300)
    }
}

struct ContextPickerRow: View {
    let item: ContextPickerView.FlatContextNode
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Indentation Guide Lines
            HStack(spacing: 0) {
                ForEach(0..<item.level, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 12)
                }
            }
            
            Image(systemName: (item.node.children?.isEmpty == false) ? "circle.fill" : "circle")
                .foregroundStyle(.secondary)
                .font(.system(size: 8))
            
            Text(item.node.name)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 4)
    }
}
