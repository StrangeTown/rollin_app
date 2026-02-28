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
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4]
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

// Typealiases for easy access to the latest version
typealias Item = SchemaV4.Item
typealias ContextNode = SchemaV4.ContextNode
