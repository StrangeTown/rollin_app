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
    @Query(sort: \ContextNode.name)
    private var allContexts: [ContextNode]
    
    @Binding var selectedContext: ContextNode?
    @State private var searchText = ""
    
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
            if let children = node.children {
                let sortedChildren = children.sorted { $0.name < $1.name }
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
                ContextPickerRow(item: item, isSelected: selectedContext == item.node)
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
