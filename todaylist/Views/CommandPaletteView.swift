import SwiftUI
import AppKit

struct CommandPaletteCommand: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let shortcut: String
    let keywords: [String]
    let action: () -> Void
}

struct CommandPaletteView: View {
    let commands: [CommandPaletteCommand]
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var selectedCommandID: String?
    @State private var keyMonitor: Any?
    @FocusState private var isSearchFocused: Bool
    @AppStorage("LastUsedCommandID") private var lastUsedCommandID: String = ""

    private var filteredCommands: [CommandPaletteCommand] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prioritize last used command
        var activeCommands = commands
        if !lastUsedCommandID.isEmpty,
           let index = activeCommands.firstIndex(where: { $0.id == lastUsedCommandID }) {
            let element = activeCommands.remove(at: index)
            activeCommands.insert(element, at: 0)
        }
        
        guard !trimmed.isEmpty else { return activeCommands }

        let tokens = trimmed.lowercased().split(whereSeparator: \.isWhitespace)
        return activeCommands.filter { command in
            let haystack = ([command.title, command.subtitle, command.shortcut] + command.keywords)
                .joined(separator: " ")
                .lowercased()
            return tokens.allSatisfy { haystack.contains(String($0)) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                
                TextField("搜索命令", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .light))
                    .focused($isSearchFocused)
                    .onSubmit {
                        executeSelectedCommand()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(.background)
            
            Divider()
                .opacity(0.6)

            // Results List
            if filteredCommands.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "command.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No matching commands")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.03))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCommands) { command in
                                CommandRow(
                                    command: command,
                                    isSelected: selectedCommandID == command.id,
                                    isLastUsed: command.id == lastUsedCommandID,
                                    action: { execute(command) }
                                )
                                .id(command.id)
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.03))
                    .onChange(of: selectedCommandID) { _, newValue in
                        guard let target = newValue else { return }
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, idealWidth: 600, maxWidth: 700, minHeight: 320, idealHeight: 400, maxHeight: 500)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            syncSelection()
            isSearchFocused = true
            installKeyMonitor()
        }
        .onChange(of: searchText) { _, _ in
            syncSelection()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }
    
    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 125: // down arrow
                moveSelection(by: 1)
                return nil
            case 126: // up arrow
                moveSelection(by: -1)
                return nil
            case 36, 76: // return / keypad enter
                executeSelectedCommand()
                return nil
            case 53: // esc
                onClose()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func syncSelection() {
        guard !filteredCommands.isEmpty else {
            selectedCommandID = nil
            return
        }

        if let selectedCommandID,
           filteredCommands.contains(where: { $0.id == selectedCommandID }) {
            return
        }

        selectedCommandID = filteredCommands.first?.id
    }

    private func moveSelection(by offset: Int) {
        guard !filteredCommands.isEmpty else { return }
        let ids = filteredCommands.map(\.id)
        let currentIndex = ids.firstIndex(of: selectedCommandID ?? "") ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), ids.count - 1)
        selectedCommandID = ids[nextIndex]
    }

    private func executeSelectedCommand() {
        guard let selectedCommandID else {
            execute(filteredCommands.first)
            return
        }

        let command = filteredCommands.first(where: { $0.id == selectedCommandID })
        execute(command)
    }

    private func execute(_ command: CommandPaletteCommand?) {
        guard let command else { return }
        
        // Save last used command
        UserDefaults.standard.set(command.id, forKey: "LastUsedCommandID")
        
        onClose()
        DispatchQueue.main.async {
            command.action()
        }
    }
}

struct CommandRow: View {
    let command: CommandPaletteCommand
    let isSelected: Bool
    let isLastUsed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator strip
                Rectangle()
                    .fill(isSelected ? Theme.Colors.todayAccent : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(command.title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.9))
                    
                    Text(command.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? Color.secondary : Color.secondary.opacity(0.8))
                }
                
                Spacer(minLength: 8)
                
                if isLastUsed {
                    Text("最近使用")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.trailing, 4)
                }
                
                if !command.shortcut.isEmpty {
                    Text(command.shortcut)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                .background(Color.secondary.opacity(0.05))
                        )
                }
            }
            .padding(.vertical, 10)
            .padding(.trailing, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            Rectangle()
                .fill(isSelected ? Theme.Colors.todayAccent.opacity(0.08) : Color.clear)
        )
    }
}
