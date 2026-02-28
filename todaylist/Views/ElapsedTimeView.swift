//
//  ElapsedTimeView.swift
//  todaylist
//

import SwiftUI

struct ElapsedTimeView: View {
    let since: Date
    let accumulated: TimeInterval

    var body: some View {
        TimelineView(.periodic(from: since, by: 60)) { context in
            let total = accumulated + context.date.timeIntervalSince(since)
            Text("\u{23F1} \(Self.formatDuration(total))")
                .font(Theme.Fonts.completionTime)
                .foregroundStyle(Theme.Colors.todayAccent.opacity(0.7))
        }
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(max(minutes, 1))m"
    }
}
