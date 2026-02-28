import SwiftUI

struct CompletionProgressPill: View {
    let completed: Int
    let total: Int
    let font: Font
    let incompleteCompletedColor: Color
    let totalColor: Color
    let useCapsuleBackground: Bool

    init(
        completed: Int,
        total: Int,
        font: Font = .caption,
        incompleteCompletedColor: Color = .primary,
        totalColor: Color = .secondary,
        useCapsuleBackground: Bool = true
    ) {
        self.completed = completed
        self.total = total
        self.font = font
        self.incompleteCompletedColor = incompleteCompletedColor
        self.totalColor = totalColor
        self.useCapsuleBackground = useCapsuleBackground
    }

    var body: some View {
        HStack(spacing: 3) {
            Text("\(completed)")
                .fontWeight(.semibold)
                .foregroundStyle(completed == total ? .green : incompleteCompletedColor)
            Text("/")
                .foregroundStyle(.tertiary)
            Text("\(total)")
                .foregroundStyle(totalColor)
        }
        .font(font)
        .padding(.horizontal, useCapsuleBackground ? 8 : 0)
        .padding(.vertical, useCapsuleBackground ? 3 : 0)
        .background(useCapsuleBackground ? Theme.Colors.breadcrumbBackground : Color.clear)
        .clipShape(Capsule())
    }
}

struct CopyFeedbackButton: View {
    let isHovered: Bool
    let helpText: String
    let iconFont: Font
    let idleColor: Color
    let useCircleBackground: Bool
    let action: () -> Void

    @State private var showCopied = false
    @State private var feedbackTask: Task<Void, Never>?

    init(
        isHovered: Bool,
        helpText: String,
        iconFont: Font = .caption,
        idleColor: Color = .secondary,
        useCircleBackground: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isHovered = isHovered
        self.helpText = helpText
        self.iconFont = iconFont
        self.idleColor = idleColor
        self.useCircleBackground = useCircleBackground
        self.action = action
    }

    var body: some View {
        if isHovered || showCopied {
            Button {
                action()
                showCopied = true
                feedbackTask?.cancel()
                feedbackTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    if !Task.isCancelled {
                        showCopied = false
                    }
                }
            } label: {
                if useCircleBackground {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(iconFont)
                        .foregroundStyle(showCopied ? .green : idleColor)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                } else {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(iconFont)
                        .foregroundStyle(showCopied ? .green : idleColor)
                }
            }
            .buttonStyle(.plain)
            .transition(.opacity)
            .help(helpText)
            .onDisappear {
                feedbackTask?.cancel()
                feedbackTask = nil
            }
        }
    }
}
