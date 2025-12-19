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
    
    private var flatContexts: [FlatContextNode] {
        let roots = allContexts.filter { $0.parent == nil }
        return flatten(roots)
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
                    Text("None")
                    Spacer()
                    if selectedContext == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            .foregroundStyle(.primary)
            
            ForEach(flatContexts) { item in
                Button {
                    selectedContext = item.node
                    dismiss()
                } label: {
                    HStack {
                        Text(item.node.name)
                            .padding(.leading, CGFloat(item.level * 20))
                        Spacer()
                        if selectedContext == item.node {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Select Context")
    }
}
