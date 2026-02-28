import Foundation

struct ReviewReportBuilder {
    static func fullReportMarkdown(data: ComputedReviewData, dateRangeText: String) -> String {
        var lines: [String] = []
        lines.append("# Review")
        lines.append(dateRangeText)
        lines.append("")
        lines.append("**Total:** \(data.totalCount) | **Done:** \(data.completedCount)")
        lines.append("")

        if !data.inboxItems.isEmpty {
            lines.append("## Inbox")
            lines.append("")
            for item in data.inboxItems {
                lines.append(taskLine(for: item))
            }
            lines.append("")
        }

        for contextData in data.rootContextData {
            lines.append(contentsOf: contextMarkdown(for: contextData))
        }

        return lines.joined(separator: "\n")
    }

    static func contextOnlyMarkdown(for data: RootContextData) -> String {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("(\(data.completedTaskCount)/\(data.totalTaskCount) completed)")
        lines.append("")

        for item in data.directTasks {
            lines.append(taskLine(for: item))
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, depth: 0))
        }

        return lines.joined(separator: "\n")
    }

    private static func contextMarkdown(for data: RootContextData) -> [String] {
        var lines: [String] = []
        lines.append("## \(data.context.name)")
        lines.append("")

        for item in data.directTasks {
            lines.append(taskLine(for: item))
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, depth: 0))
        }

        lines.append("")
        return lines
    }

    private static func childMarkdown(for data: ChildContextData, depth: Int) -> [String] {
        let indent = indentation(depth)
        var lines: [String] = []
        lines.append("")
        lines.append("\(indent)### \(data.context.name)")

        for item in data.tasks {
            lines.append(taskLine(for: item, indent: indent))
        }

        for child in data.children {
            lines.append(contentsOf: childMarkdown(for: child, depth: depth + 1))
        }

        return lines
    }

    private static func taskLine(for item: Item, indent: String = "") -> String {
        let status = item.isCompleted ? "[x]" : "[ ]"
        return "\(indent)- \(status) \(item.title)"
    }

    private static func indentation(_ depth: Int) -> String {
        String(repeating: "  ", count: max(0, depth))
    }
}
