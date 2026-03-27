//
//  Theme.swift
//  todaylist
//
//  Design system for consistent styling across the app
//

import SwiftUI

// MARK: - Theme
enum Theme {
    
    // MARK: - Colors
    enum Colors {
        /// Primary accent color (consistent across light/dark)
        static let accent = Color.accentColor
        
        /// Today section accent - slightly emphasized blue
        static let todayAccent = Color(
            light: Color(red: 0.2, green: 0.5, blue: 0.95),
            dark: Color(red: 0.4, green: 0.65, blue: 1.0)
        )
        
        /// Completed task text color
        static let completedText = Color(
            light: Color.secondary.opacity(0.6),
            dark: Color.secondary.opacity(0.65)
        )
        
        /// Completed task completion time
        static let completionTime = Color(
            light: Color.secondary.opacity(0.5),
            dark: Color.secondary.opacity(0.55)
        )
        
        /// Breadcrumb background
        static let breadcrumbBackground = Color(
            light: Color.gray.opacity(0.08),
            dark: Color.gray.opacity(0.2)
        )
        
        /// Breadcrumb text
        static let breadcrumbText = Color(
            light: Color.secondary,
            dark: Color.secondary.opacity(0.9)
        )
        
        /// Badge active (has items) background
        static let badgeActive = Color(
            light: Color.blue.opacity(0.12),
            dark: Color.blue.opacity(0.25)
        )
        
        /// Badge active text
        static let badgeActiveText = Color(
            light: Color.blue.opacity(0.8),
            dark: Color.blue.opacity(0.9)
        )
        
        /// Badge default background
        static let badgeDefault = Color(
            light: Color.gray.opacity(0.1),
            dark: Color.gray.opacity(0.2)
        )
        
        /// Hover state background
        static let hoverBackground = Color(
            light: Color.primary.opacity(0.05),
            dark: Color.primary.opacity(0.08)
        )
        
        /// Selection background
        static let selectionBackground = Color.accentColor
        
        /// Muted action button (like X button)
        static let mutedAction = Color(
            light: Color.secondary.opacity(0.4),
            dark: Color.secondary.opacity(0.5)
        )
        
        /// Subtle red for incomplete Today tasks
        static let todayIncomplete = Color(
            light: Color(red: 0.85, green: 0.25, blue: 0.25).opacity(0.55),
            dark: Color(red: 1.0, green: 0.45, blue: 0.45).opacity(0.55)
        )

        /// Priority title color for Today tasks
        static let todayPriorityTitle = Color(
            light: Color(red: 0.56, green: 0.24, blue: 0.24),
            dark: Color(red: 0.74, green: 0.43, blue: 0.43)
        )
        static let primaryText = Color(
            light: Color(red: 0.15, green: 0.15, blue: 0.17),
            dark: Color(red: 0.92, green: 0.92, blue: 0.92)
        )
        
        /// Timeline task title - soft charcoal instead of pure black
        static let timelineText = Color(
            light: Color(red: 0.11, green: 0.11, blue: 0.12),  // #1C1C1E
            dark: Color(red: 0.92, green: 0.92, blue: 0.92)
        )
        
        /// Timeline timestamp - muted gray
        static let timelineTimestamp = Color(
            light: Color(red: 0.56, green: 0.56, blue: 0.58),  // #8E8E93
            dark: Color(red: 0.6, green: 0.6, blue: 0.62)
        )
        
        /// Timeline tag background - very light, almost white
        static let timelineTagBackground = Color(
            light: Color(red: 0.95, green: 0.95, blue: 0.97),  // #F2F2F7
            dark: Color.gray.opacity(0.18)
        )
    }
    
    // MARK: - Fonts
    enum Fonts {
        /// Section header (Today, Yesterday, etc.)
        static let sectionHeader = Font.subheadline
        
        /// Today label - emphasized
        static let todayLabel = Font.subheadline.bold()
        
        /// Task title
        static let taskTitle = Font.body
        
        /// Breadcrumb / context path
        static let breadcrumb = Font.caption
        
        /// Badge count
        static let badge = Font.caption
        
        /// Completion time
        static let completionTime = Font.caption
        
        /// Node indicator
        static let nodeIndicator = Font.system(size: 8)
        
        /// Chevron indicator
        static let chevronIndicator = Font.system(size: 10, weight: .medium)
    }
    
    // MARK: - Spacing
    enum Spacing {
        /// Vertical spacing between list items
        static let listItemVertical: CGFloat = 4

        /// Internal spacing in task row
        static let taskRowInternal: CGFloat = 4

        /// Sidebar item padding
        static let sidebarItemVertical: CGFloat = 6
        static let sidebarItemHorizontal: CGFloat = 8

        /// Child node indentation - increased for better hierarchy
        static let childIndent: CGFloat = 20

        /// Badge padding
        static let badgeHorizontal: CGFloat = 6
        static let badgeVertical: CGFloat = 2

        /// Breadcrumb padding
        static let breadcrumbHorizontal: CGFloat = 6
        static let breadcrumbVertical: CGFloat = 2

        /// Dialog spacing
        static let dialogPadding: CGFloat = 24
        static let dialogSection: CGFloat = 20
        static let dialogTitle: CGFloat = 12
        static let dialogInputHeight: CGFloat = 34
    }
    
    // MARK: - Icons (Linear style)
    enum Icons {
        // Task states
        static let taskIncomplete = "circle"
        static let taskComplete = "checkmark.circle"
        
        // Actions
        static let moveToToday = "sun.max"
        static let removeFromToday = "minus.circle"
        static let edit = "pencil"
        static let delete = "trash"
        static let moveToInbox = "tray"
        static let add = "plus"
        static let copy = "doc.on.doc"
        static let dismiss = "xmark.circle"
        static let timeline = "clock"
        static let calendar = "calendar"
        static let folder = "folder"
        static let priority = "flag"
        static let priorityOff = "flag.slash"
        
        // Node indicators
        static let nodeParent = "chevron.right"
        static let nodeLeaf = "circle"
        
        // Timer
        static let startTask = "play.circle"
        static let pauseTask = "pause.circle"
        static let timer = "timer"

        // Empty states
        static let emptyCalendar = "calendar"
        static let emptyContext = "circle.dotted"
        static let emptyTimeline = "checkmark.circle"
        static let celebration = "party.popper"
    }
    
    // MARK: - Animation
    enum Animation {
        /// Task completion bounce
        static let completionBounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        
        /// Standard transition
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        
        /// Dialog appear/disappear - elegant spring for Spotlight-like feel
        static let dialog = SwiftUI.Animation.spring(duration: 0.25)
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let dialog: CGFloat = 16
    }

    // MARK: - Limits
    enum Limits {
        /// Maximum number of context hierarchy levels (1-based).
        /// e.g. 3 means: root → child → grandchild, no deeper.
        static let maxContextDepth = 3
    }
}

// MARK: - Color Extension for Light/Dark Mode
extension Color {
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua:
                return NSColor(dark)
            default:
                return NSColor(light)
            }
        }))
    }
}

// MARK: - View Modifiers

/// Breadcrumb tag style modifier
struct BreadcrumbTagStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.breadcrumb)
            .foregroundStyle(Theme.Colors.breadcrumbText)
            .padding(.horizontal, Theme.Spacing.breadcrumbHorizontal)
            .padding(.vertical, Theme.Spacing.breadcrumbVertical)
            .background(Theme.Colors.breadcrumbBackground)
            .clipShape(Capsule())
    }
}

/// Badge style modifier - simplified for better visual hierarchy
struct BadgeStyle: ViewModifier {
    let isActive: Bool
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.system(size: 11))
            .foregroundStyle(badgeTextColor)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(badgeBackgroundColor)
            .clipShape(Capsule())
    }

    private var badgeTextColor: Color {
        if isSelected {
            return .white.opacity(0.9)
        }
        // 未选中时使用柔和的灰色
        return .secondary
    }

    private var badgeBackgroundColor: Color {
        if isSelected {
            return .white.opacity(0.2)
        }
        // 未选中时使用极淡的背景或透明
        return isActive ? Color.gray.opacity(0.1) : Color.clear
    }
}

extension View {
    func breadcrumbTagStyle() -> some View {
        modifier(BreadcrumbTagStyle())
    }
    
    func badgeStyle(isActive: Bool = false, isSelected: Bool = false) -> some View {
        modifier(BadgeStyle(isActive: isActive, isSelected: isSelected))
    }
}
