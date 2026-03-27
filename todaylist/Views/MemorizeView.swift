import SwiftUI
import SwiftData


struct MemorizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemorizeItem.createdAt, order: .reverse) private var items: [MemorizeItem]

    @State private var newContent: String = ""
    @State private var editingItem: MemorizeItem?
    @State private var editingContent: String = ""
    @State private var randomItem: MemorizeItem?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HSplitView {
            // MARK: - Left panel
            leftPanel
                .frame(minWidth: 450, idealWidth: 500)
                .background(Color(NSColor.textBackgroundColor))

            // MARK: - Right panel
            rightPanel
                .frame(minWidth: 400, idealWidth: 500)
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            isInputFocused = true
            pickRandom()
        }
        .onKeyPress(.rightArrow) {
            pickRandom()
            return .handled
        }
        .onChange(of: items.count) {
            if randomItem == nil || !items.contains(where: { $0.id == randomItem?.id }) {
                pickRandom()
            }
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // List
            if items.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "brain")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("还没有要点")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("添加工作中需要记住的核心要点，\n帮助自己在实践中快速回忆。")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 40)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(items) { item in
                            itemRow(item)
                        }
                    }
                    .padding(24)
                }
            }

            Divider()

            // Input area (Bottom)
            VStack(spacing: 0) {
                HStack(alignment: .bottom, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        if newContent.isEmpty {
                            Text("输入新的工作要点…")
                                .foregroundStyle(.tertiary)
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $newContent)
                            .font(.body)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .frame(minHeight: 40, maxHeight: 120)
                            .focused($isInputFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .onKeyPress(.return, phases: .down) { press in
                                guard press.modifiers.contains(.command) else { return .ignored }
                                addItem()
                                return .handled
                            }
                    }

                    Button(action: addItem) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(newContent.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary.opacity(0.3) : .purple)
                    }
                    .buttonStyle(.plain)
                    .disabled(newContent.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.bottom, 6)
                }
                
                HStack {
                    Text("可以用 ⌘+↩ 快速提交")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
            }
            .padding(20)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private func itemRow(_ item: MemorizeItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if editingItem?.id == item.id {
                TextEditor(text: $editingContent)
                    .font(.body)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(minHeight: 60, maxHeight: 160)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    )
                    .onKeyPress(.return, phases: .down) { press in
                        guard press.modifiers.contains(.command) else { return .ignored }
                        saveEdit(item)
                        return .handled
                    }
                
                HStack {
                    Spacer()
                    Button("取消") {
                        editingItem = nil
                        editingContent = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    
                    Button("保存 (⌘↩)") { saveEdit(item) }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.small)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {

                    Text(item.content)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    HStack(spacing: 16) {
                        Button {
                            editingItem = item
                            editingContent = item.content
                        } label: {
                            Image(systemName: "pencil")
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("编辑")

                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                deleteItem(item)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary.opacity(0.8))
                        .help("删除")
                    }
                    .opacity(0.6)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 0) {

            if let item = randomItem {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView {
                        Text(item.content)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(10)
                            .foregroundStyle(.primary.opacity(0.9))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 500)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                
                Spacer()
            } else {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("暂无内容可供复习")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            HStack(spacing: 4) {
                Text("按")
                Image(systemName: "arrow.right.square.fill")
                Text("随机下一条")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.vertical, 24)
        }
    }

    private func addItem() {
        let trimmed = newContent.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = MemorizeItem(content: trimmed)
        modelContext.insert(item)
        newContent = ""
        if randomItem == nil { randomItem = item }
    }

    private func saveEdit(_ item: MemorizeItem) {
        let trimmed = editingContent.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        item.content = trimmed
        editingItem = nil
        editingContent = ""
    }

    private func deleteItem(_ item: MemorizeItem) {
        if randomItem?.id == item.id { randomItem = nil }
        modelContext.delete(item)
    }

    private func pickRandom() {
        guard !items.isEmpty else { randomItem = nil; return }
        if items.count == 1 {
            randomItem = items.first
        } else {
            var next = items.randomElement()
            while next?.id == randomItem?.id {
                next = items.randomElement()
            }
            randomItem = next
        }
    }
}
