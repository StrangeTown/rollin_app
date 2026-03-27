import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("retentionDays") private var retentionDays: Int = 365
    @State private var showCleanupAlert = false
    @State private var cleanedCount = 0
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Retention Policy
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Data Retention")
                                .font(.headline)
                            Text("Manage how long completed tasks are kept.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Picker("Keep Completed Tasks", selection: $retentionDays) {
                        Text("1 Week").tag(7)
                        Text("1 Month").tag(30)
                        Text("3 Months").tag(90)
                        Text("1 Year").tag(365)
                        Text("Forever").tag(9999)
                    }
                    .pickerStyle(.menu)
                    
                    Text("Tasks completed more than \(retentionDays == 9999 ? "forever" : "\(retentionDays) days") ago will be permanently deleted on app launch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                
                // Section 2: Context Hierarchy
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.accent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Context 层级")
                                .font(.headline)
                            Text("Context 最多支持 \(Theme.Limits.maxContextDepth) 层嵌套（根 / 子级 / 孙级），超出层级后将不显示添加入口。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Section 3: Manual Action
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clean Up Now")
                                .font(.body)
                            Text("Manually remove old tasks immediately.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            let count = DataCleanupManager.cleanOldTasks(context: modelContext, daysToKeep: retentionDays)
                            cleanedCount = count
                            showCleanupAlert = true
                        } label: {
                            Text("Clean")
                                .frame(minWidth: 60)
                        }
                        .controlSize(.regular)
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Cleanup Complete", isPresented: $showCleanupAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Removed \(cleanedCount) old tasks.")
            }
        }
        .frame(width: 450, height: 420)
    }
}

#Preview {
    SettingsView()
}
