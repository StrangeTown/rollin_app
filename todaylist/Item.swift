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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
