import SwiftUI
import SwiftData

struct DataCleanupManager {
    /// 执行清理操作
    /// - Parameters:
    ///   - context: SwiftData 的 ModelContext
    ///   - daysToKeep: 保留多少天的数据（默认 30 天）
    /// - Returns: 清理了多少条数据
    @MainActor
    @discardableResult
    static func cleanOldTasks(context: ModelContext, daysToKeep: Int = 30) -> Int {
        // 如果设置为 9999，则不清理
        if daysToKeep >= 9999 { return 0 }
        
        // 1. 计算截止日期 (当前时间 - daysToKeep)
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -daysToKeep, to: Date()) else {
            return 0
        }
        
        // 2. 创建查询描述符：查找所有“已完成”且“完成时间早于截止日期”的任务
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { item in
                item.isCompleted && item.completedAt != nil && item.completedAt! < cutoffDate
            }
        )
        
        do {
            // 3. 获取符合条件的数据
            let itemsToDelete = try context.fetch(descriptor)
            let count = itemsToDelete.count
            
            if count > 0 {
                // 4. 执行删除
                for item in itemsToDelete {
                    context.delete(item)
                }
                
                // 5. 保存更改
                try context.save()
                print("🧹 Data Cleanup: Removed \(count) completed tasks older than \(daysToKeep) days.")
            } else {
                print("🧹 Data Cleanup: No old tasks to clean.")
            }
            
            return count
        } catch {
            print("❌ Data Cleanup Error: \(error)")
            return 0
        }
    }
}
