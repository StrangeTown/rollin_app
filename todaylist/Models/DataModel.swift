//
//  DataModel.swift
//  todaylist
//
//  Created by GitHub Copilot on 2025/12/19.
//

import Foundation
import SwiftData

// MARK: - Migration Plan

enum DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self, SchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5, migrateV5toV6]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    static let migrateV5toV6 = MigrationStage.lightweight(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self
    )
}

// MARK: - Schema V1 (Original)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Item.self]
    }
    
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
}

// MARK: - Schema V2 (Current)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Item.self, ContextNode.self]
    }
    
    @Model
    final class Item {
        var title: String = ""
        var timestamp: Date = Date()
        var isCompleted: Bool = false
        var isToday: Bool = false
        var assignedDate: Date? = nil
        var completedAt: Date? = nil
        
        // New relationship
        var context: ContextNode?
        
        init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil, context: ContextNode? = nil) {
            self.title = title
            self.timestamp = timestamp
            self.isCompleted = isCompleted
            self.isToday = isToday
            self.assignedDate = assignedDate
            self.completedAt = completedAt
            self.context = context
        }
    }
    
    @Model
    final class ContextNode {
        var name: String = ""
        var id: UUID = UUID()
        
        var parent: ContextNode?
        @Relationship(deleteRule: .cascade, inverse: \ContextNode.parent)
        var children: [ContextNode]? = []
        
        @Relationship(deleteRule: .nullify, inverse: \Item.context)
        var items: [Item]? = []
        
        init(name: String, parent: ContextNode? = nil) {
            self.name = name
            self.parent = parent
        }
        
        var fullPath: String {
            if let parent = parent {
                return parent.fullPath + " / " + name
            } else {
                return name
            }
        }
    }
}

// MARK: - Schema V3 (Current)

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ContextNode.self]
    }

    @Model
    final class Item {
        var title: String = ""
        var timestamp: Date = Date()
        var isCompleted: Bool = false
        var isToday: Bool = false
        var assignedDate: Date? = nil
        var completedAt: Date? = nil

        // New relationship
        var context: ContextNode?

        init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil, context: ContextNode? = nil) {
            self.title = title
            self.timestamp = timestamp
            self.isCompleted = isCompleted
            self.isToday = isToday
            self.assignedDate = assignedDate
            self.completedAt = completedAt
            self.context = context
        }
    }

    @Model
    final class ContextNode {
        var name: String = ""
        var id: UUID = UUID()
        var sortOrder: Int = 0

        var parent: ContextNode?
        @Relationship(deleteRule: .cascade, inverse: \ContextNode.parent)
        var children: [ContextNode]? = []

        @Relationship(deleteRule: .nullify, inverse: \Item.context)
        var items: [Item]? = []

        init(name: String, parent: ContextNode? = nil) {
            self.name = name
            self.parent = parent
        }

        var fullPath: String {
            if let parent = parent {
                return parent.fullPath + " / " + name
            } else {
                return name
            }
        }
    }
}

// MARK: - Schema V4 (Current)

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ContextNode.self]
    }

    @Model
    final class Item {
        var title: String = ""
        var timestamp: Date = Date()
        var isCompleted: Bool = false
        var isToday: Bool = false
        var assignedDate: Date? = nil
        var completedAt: Date? = nil

        // Relationship
        var context: ContextNode?

        // Timer fields
        var startedAt: Date? = nil
        var accumulatedDuration: TimeInterval = 0

        // Computed: total duration including current active segment
        var totalDuration: TimeInterval? {
            guard hasBeenTracked else { return nil }
            if let startedAt, !isCompleted {
                return accumulatedDuration + Date().timeIntervalSince(startedAt)
            }
            return accumulatedDuration
        }

        // Whether currently being timed
        var isInProgress: Bool {
            startedAt != nil && !isCompleted
        }

        // Whether this task has ever been tracked
        var hasBeenTracked: Bool {
            accumulatedDuration > 0 || startedAt != nil
        }

        init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil, context: ContextNode? = nil) {
            self.title = title
            self.timestamp = timestamp
            self.isCompleted = isCompleted
            self.isToday = isToday
            self.assignedDate = assignedDate
            self.completedAt = completedAt
            self.context = context
        }
    }

    @Model
    final class ContextNode {
        var name: String = ""
        var id: UUID = UUID()
        var sortOrder: Int = 0

        var parent: ContextNode?
        @Relationship(deleteRule: .cascade, inverse: \ContextNode.parent)
        var children: [ContextNode]? = []

        @Relationship(deleteRule: .nullify, inverse: \Item.context)
        var items: [Item]? = []

        init(name: String, parent: ContextNode? = nil) {
            self.name = name
            self.parent = parent
        }

        var fullPath: String {
            if let parent = parent {
                return parent.fullPath + " / " + name
            } else {
                return name
            }
        }
    }
}

// MARK: - Schema V5 (Current)

enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ContextNode.self]
    }

    @Model
    final class Item {
        var title: String = ""
        var timestamp: Date = Date()
        var isCompleted: Bool = false
        var isToday: Bool = false
        var assignedDate: Date? = nil
        var completedAt: Date? = nil

        // Relationship
        var context: ContextNode?

        // Timer fields
        var startedAt: Date? = nil
        var accumulatedDuration: TimeInterval = 0

        // "Today priority" marker (valid only for the day it was set)
        var todayPriorityDate: Date? = nil

        // Computed: total duration including current active segment
        var totalDuration: TimeInterval? {
            guard hasBeenTracked else { return nil }
            if let startedAt, !isCompleted {
                return accumulatedDuration + Date().timeIntervalSince(startedAt)
            }
            return accumulatedDuration
        }

        // Whether currently being timed
        var isInProgress: Bool {
            startedAt != nil && !isCompleted
        }

        // Whether this task has ever been tracked
        var hasBeenTracked: Bool {
            accumulatedDuration > 0 || startedAt != nil
        }

        init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil, context: ContextNode? = nil) {
            self.title = title
            self.timestamp = timestamp
            self.isCompleted = isCompleted
            self.isToday = isToday
            self.assignedDate = assignedDate
            self.completedAt = completedAt
            self.context = context
        }
    }

    @Model
    final class ContextNode {
        var name: String = ""
        var id: UUID = UUID()
        var sortOrder: Int = 0

        var parent: ContextNode?
        @Relationship(deleteRule: .cascade, inverse: \ContextNode.parent)
        var children: [ContextNode]? = []

        @Relationship(deleteRule: .nullify, inverse: \Item.context)
        var items: [Item]? = []

        init(name: String, parent: ContextNode? = nil) {
            self.name = name
            self.parent = parent
        }

        var fullPath: String {
            if let parent = parent {
                return parent.fullPath + " / " + name
            } else {
                return name
            }
        }
    }
}

// MARK: - Schema V6 (Current)

enum SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self, ContextNode.self, MemorizeItem.self]
    }

    @Model
    final class Item {
        var title: String = ""
        var timestamp: Date = Date()
        var isCompleted: Bool = false
        var isToday: Bool = false
        var assignedDate: Date? = nil
        var completedAt: Date? = nil

        var context: ContextNode?

        var startedAt: Date? = nil
        var accumulatedDuration: TimeInterval = 0

        var todayPriorityDate: Date? = nil

        var totalDuration: TimeInterval? {
            guard hasBeenTracked else { return nil }
            if let startedAt, !isCompleted {
                return accumulatedDuration + Date().timeIntervalSince(startedAt)
            }
            return accumulatedDuration
        }

        var isInProgress: Bool {
            startedAt != nil && !isCompleted
        }

        var hasBeenTracked: Bool {
            accumulatedDuration > 0 || startedAt != nil
        }

        init(title: String = "", timestamp: Date = Date(), isCompleted: Bool = false, isToday: Bool = false, assignedDate: Date? = nil, completedAt: Date? = nil, context: ContextNode? = nil) {
            self.title = title
            self.timestamp = timestamp
            self.isCompleted = isCompleted
            self.isToday = isToday
            self.assignedDate = assignedDate
            self.completedAt = completedAt
            self.context = context
        }
    }

    @Model
    final class ContextNode {
        var name: String = ""
        var id: UUID = UUID()
        var sortOrder: Int = 0

        var parent: ContextNode?
        @Relationship(deleteRule: .cascade, inverse: \ContextNode.parent)
        var children: [ContextNode]? = []

        @Relationship(deleteRule: .nullify, inverse: \Item.context)
        var items: [Item]? = []

        init(name: String, parent: ContextNode? = nil) {
            self.name = name
            self.parent = parent
        }

        var fullPath: String {
            if let parent = parent {
                return parent.fullPath + " / " + name
            } else {
                return name
            }
        }
    }

    @Model
    final class MemorizeItem {
        var id: UUID = UUID()
        var content: String = ""
        var createdAt: Date = Date()

        init(content: String) {
            self.content = content
        }
    }
}

// Typealiases for easy access to the latest version
typealias Item = SchemaV6.Item
typealias ContextNode = SchemaV6.ContextNode
typealias MemorizeItem = SchemaV6.MemorizeItem
