//
//  FocusStatusBarController.swift
//  todaylist
//
//  用 AppKit 直接管理菜单栏的「专注计时」入口。
//  之所以不用 SwiftUI 的 MenuBarExtra：之前在 App Scene 层引入第二个 MenuBarExtra
//  并由 @Observable 共享状态驱动 isInserted 时，应用会在「开始专注」瞬间卡死。
//  改用 NSStatusItem + Timer 后，菜单栏更新走纯 AppKit 路径，与 SwiftUI 渲染树解耦。
//

import AppKit
import Foundation

@MainActor
final class FocusStatusBarController: NSObject {
    static let shared = FocusStatusBarController()

    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var startedAt: Date?
    private var taskTitle: String?

    private override init() {
        super.init()
    }

    /// 开始/重启计时器；如果 startedAt 没变，仅刷新标题。
    func start(taskTitle: String?, startedAt: Date) {
        self.taskTitle = taskTitle
        self.startedAt = startedAt
        ensureStatusItem()
        rebuildMenu()
        startTimer()
        refreshDisplay()
    }

    /// 计时进行中、任务标题被改名时调用。
    func updateTitle(_ taskTitle: String?) {
        guard startedAt != nil else { return }
        self.taskTitle = taskTitle
        rebuildMenu()
    }

    /// 完成 / 取消 / 关闭计时；从菜单栏移除条目。
    func stop() {
        startedAt = nil
        taskTitle = nil
        timer?.invalidate()
        timer = nil
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // MARK: - Internals

    private func ensureStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "target", accessibilityDescription: "Focus Timer")
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        }
        statusItem = item
    }

    private func rebuildMenu() {
        guard let statusItem else { return }
        let menu = NSMenu()

        if let title = taskTitle, !title.isEmpty {
            let titleItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)
            menu.addItem(.separator())
        }

        let openItem = NSMenuItem(title: "打开 Follin", action: #selector(activateApp), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        statusItem.menu = menu
    }

    private func startTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisplay()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func refreshDisplay() {
        guard let started = startedAt, let button = statusItem?.button else { return }
        let elapsed = Date().timeIntervalSince(started)
        button.title = " " + Self.formatElapsed(elapsed)
    }

    @objc private func activateApp() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private static func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
