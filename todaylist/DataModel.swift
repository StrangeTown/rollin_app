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
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
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

// Typealiases for easy access to the latest version
typealias Item = SchemaV2.Item
typealias ContextNode = SchemaV2.ContextNode
