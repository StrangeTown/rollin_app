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
        static let listItemVertical: CGFloat = 6
        
        /// Internal spacing in task row
        static let taskRowInternal: CGFloat = 4
        
        /// Sidebar item padding
        static let sidebarItemVertical: CGFloat = 6
        static let sidebarItemHorizontal: CGFloat = 8
        
        /// Child node indentation
        static let childIndent: CGFloat = 16
        
        /// Badge padding
        static let badgeHorizontal: CGFloat = 6
        static let badgeVertical: CGFloat = 2
        
        /// Breadcrumb padding
        static let breadcrumbHorizontal: CGFloat = 6
        static let breadcrumbVertical: CGFloat = 2
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
        
        // Node indicators
        static let nodeParent = "chevron.right"
        static let nodeLeaf = "circle"
        
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
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
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

/// Badge style modifier
struct BadgeStyle: ViewModifier {
    let isActive: Bool
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(Theme.Fonts.badge)
            .foregroundStyle(badgeTextColor)
            .padding(.horizontal, Theme.Spacing.badgeHorizontal)
            .padding(.vertical, Theme.Spacing.badgeVertical)
            .background(badgeBackgroundColor)
            .clipShape(Capsule())
    }
    
    private var badgeTextColor: Color {
        if isSelected {
            return .white.opacity(0.9)
        }
        return isActive ? Theme.Colors.badgeActiveText : .secondary
    }
    
    private var badgeBackgroundColor: Color {
        if isSelected {
            return .white.opacity(0.25)
        }
        return isActive ? Theme.Colors.badgeActive : Theme.Colors.badgeDefault
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
