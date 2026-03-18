import SwiftUI
import SwiftData

struct ContextEditorSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let rootContext: ContextNode
    @Binding var selectedContext: ContextNode?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("编辑顶级 Context 容器")
                    .font(.headline)

                Text("在这里可修改名称、添加子级、删除子级。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        editableRow(for: rootContext, level: 0, isRoot: true)
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Spacer()
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
            .frame(minWidth: 560, minHeight: 420)
            .navigationTitle("Context 编辑")
            .toolbar(.hidden, for: .windowToolbar)
        }
    }

    private func editableRow(for node: ContextNode, level: Int, isRoot: Bool) -> AnyView {
        let children = sortedChildren(of: node)
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: CGFloat(level) * 18)

                    Image(systemName: isRoot ? "folder.fill" : "number")
                        .font(.system(size: isRoot ? 12 : 10, weight: isRoot ? .regular : .medium))
                        .foregroundStyle(isRoot ? Theme.Colors.todayAccent.opacity(0.85) : .secondary.opacity(0.7))

                    TextField("Context 名称", text: contextNameBinding(for: node))
                        .textFieldStyle(.roundedBorder)

                    Button {
                        addChildContext(to: node)
                    } label: {
                        Image(systemName: Theme.Icons.add)
                    }
                    .buttonStyle(.borderless)
                    .help("添加子级")

                    if !isRoot {
                        Button(role: .destructive) {
                            deleteContextNode(node)
                        } label: {
                            Image(systemName: Theme.Icons.delete)
                        }
                        .buttonStyle(.borderless)
                        .help("删除该子级")
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                        .fill(Color.secondary.opacity(isRoot ? 0.09 : 0.05))
                )

                ForEach(children, id: \.id) { child in
                    editableRow(for: child, level: level + 1, isRoot: false)
                }
            }
        )
    }

    private func contextNameBinding(for node: ContextNode) -> Binding<String> {
        Binding(
            get: { node.name },
            set: { node.name = $0 }
        )
    }

    private func sortedChildren(of node: ContextNode) -> [ContextNode] {
        (node.children ?? []).sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    private func addChildContext(to parent: ContextNode) {
        let child = ContextNode(name: "新建子级", parent: parent)
        let maxOrder = (parent.children ?? []).map(\.sortOrder).max() ?? -1
        child.sortOrder = maxOrder + 1
        modelContext.insert(child)
    }

    private func deleteContextNode(_ node: ContextNode) {
        if shouldClearSelection(whenDeleting: node) {
            selectedContext = nil
        }
        modelContext.delete(node)
    }

    private func shouldClearSelection(whenDeleting node: ContextNode) -> Bool {
        guard let currentSelection = selectedContext else {
            return false
        }
        if currentSelection.id == node.id {
            return true
        }
        return isDescendant(currentSelection, of: node)
    }

    private func isDescendant(_ node: ContextNode, of potentialAncestor: ContextNode) -> Bool {
        var cursor = node.parent
        while let current = cursor {
            if current.id == potentialAncestor.id {
                return true
            }
            cursor = current.parent
        }
        return false
    }
}
