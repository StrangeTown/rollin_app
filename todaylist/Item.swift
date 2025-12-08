//
//  Item.swift
//  todaylist
//
//  Created by 尹星 on 2025/11/20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var title: String = ""
    var timestamp: Date = Date()
    var isCompleted: Bool = false
    var isToday: Bool = false
    var assignedDate: Date? = nil
    var completedAt: Date? = nil
    
    init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil) {
        self.title = title
        self.timestamp = timestamp
        self.isCompleted = isCompleted
        self.isToday = isToday
        self.assignedDate = assignedDate
        self.completedAt = completedAt
    }
}
