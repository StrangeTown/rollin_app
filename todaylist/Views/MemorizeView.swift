import SwiftUI
import SwiftData

private let shuffleIcons = [
    "dice", "dice.fill", "arrow.trianglehead.2.clockwise", "shuffle",
    "sparkles", "wand.and.stars", "hurricane", "atom",
    "arrow.trianglehead.clockwise", "figure.walk", "hare.fill", "bolt.fill"
]

struct MemorizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemorizeItem.createdAt, order: .reverse) private var items: [MemorizeItem]

    @State private var newContent: String = ""
    @State private var editingItem: MemorizeItem?
    @State private var editingContent: String = ""
    @State private var randomItem: MemorizeItem?
    @State private var currentIcon: String = shuffleIcons.randomElement()!
    @FocusState private var isInputFocused: Bool

    var body: some View {
        HSplitView {
            // MARK: - Left panel
            leftPanel
                .frame(minWidth: 350, idealWidth: 420)

            // MARK: - Right panel
            rightPanel
                .frame(minWidth: 280, idealWidth: 320)
        }
        .frame(minWidth: 700, minHeight: 480)
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
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("Memorize")
                    .font(.title2.bold())
                Spacer()
                Text("\(items.count) 条要点")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if newContent.isEmpty {
                        Text("添加新的要点… (⌘↩ 提交)")
                            .foregroundStyle(.secondary.opacity(0.6))
                            .font(.body)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $newContent)
                        .font(.body)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .frame(minHeight: 60, maxHeight: 120)
                        .focused($isInputFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                        .onKeyPress(.return, phases: .down) { press in
                            guard press.modifiers.contains(.command) else { return .ignored }
                            addItem()
                            return .handled
                        }
                }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
                .disabled(newContent.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()

            Divider()

            // List
            if items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text("还没有要点")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("添加工作中需要记住的要点")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(items) { item in
                        if editingItem?.id == item.id {
                            HStack(alignment: .bottom) {
                                TextEditor(text: $editingContent)
                                    .font(.body)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 6)
                                    .frame(minHeight: 60, maxHeight: 120)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                                    .onKeyPress(.return, phases: .down) { press in
                                        guard press.modifiers.contains(.command) else { return .ignored }
                                        saveEdit(item)
                                        return .handled
                                    }
                                VStack(spacing: 6) {
                                    Button("保存") { saveEdit(item) }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)
                                        .controlSize(.small)
                                    Button("取消") {
                                        editingItem = nil
                                        editingContent = ""
                                    }
                                    .controlSize(.small)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow.opacity(0.8))
                                    .font(.caption)

                                Text(item.content)
                                    .lineLimit(3)

                                Spacer()

                                Text(item.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)

                                Button {
                                    editingItem = item
                                    editingContent = item.content
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)

                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.purple.opacity(0.7))
                Text("背记")
                    .font(.headline)
                Spacer()
                Text("→ 下一条")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()

            Divider()

            if let item = randomItem {
                Spacer()
                ScrollView {
                    Text(item.content)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 24)
                }
                .frame(maxHeight: .infinity)
                Spacer()
            } else {
                Spacer()
                Text("暂无要点")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Divider()

            Button(action: pickRandom) {
                Image(systemName: currentIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(.purple)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 16)
            .help("随机一条 (→)")
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
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
        currentIcon = shuffleIcons.randomElement()!
    }
}
