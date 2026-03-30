import SwiftUI
import SwiftData

enum SettingsCategory: String, CaseIterable, Identifiable {
    case data = "Data & Storage"
    case context = "Context"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .data: return "internaldrive"
        case .context: return "folder"
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL
    
    @AppStorage("retentionDays") private var retentionDays: Int = 365
    @State private var showCleanupAlert = false
    @State private var cleanedCount = 0
    
    @State private var selectedCategory: SettingsCategory = .data
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                ForEach(SettingsCategory.allCases) { category in
                    NavigationLink(value: category) {
                        Label(category.rawValue, systemImage: category.icon)
                            .padding(.vertical, 4)
                    }
                }
                
                Divider()
                
                Button {
                    openWindow(id: "memorize")
                } label: {
                    Label("Memorize", systemImage: "brain.head.profile")
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: "mailto:yinxingdyx@163.com?subject=Follin%20Feedback") {
                        openURL(url)
                    }
                } label: {
                    Label("联系作者", systemImage: "envelope")
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180, max: 220)
        } detail: {
            Group {
                switch selectedCategory {
                case .data:
                    dataSettings
                case .context:
                    contextSettings
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(NSColor.controlBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(width: 650, height: 400)
        .alert("Cleanup Complete", isPresented: $showCleanupAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Removed \(cleanedCount) old tasks.")
        }
    }
    
    private var dataSettings: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Retention")
                            .font(.headline)
                        Text("Manage how long completed tasks are kept.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Picker("", selection: $retentionDays) {
                            Text("1 Week").tag(7)
                            Text("1 Month").tag(30)
                            Text("3 Months").tag(90)
                            Text("1 Year").tag(365)
                            Text("Forever").tag(9999)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 150)
                        
                        Text("Tasks completed more than \(retentionDays == 9999 ? "forever" : "\(retentionDays) days") ago will be permanently deleted on app launch.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
            }
            
            Section {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "trash")
                        .font(.title)
                        .foregroundStyle(Color.red.opacity(0.8))
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clean Up Now")
                            .font(.headline)
                        Text("Manually remove old tasks immediately.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button(role: .destructive) {
                            let count = DataCleanupManager.cleanOldTasks(context: modelContext, daysToKeep: retentionDays)
                            cleanedCount = count
                            showCleanupAlert = true
                        } label: {
                            Text("Clean")
                                .padding(.horizontal, 16)
                        }
                        .controlSize(.regular)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .formStyle(.grouped)
    }
    
    private var contextSettings: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.title)
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context 层级")
                            .font(.headline)
                        Text("Context 最多支持 \(Theme.Limits.maxContextDepth) 层嵌套（根 / 子级 / 孙级）。超出此限制后将不再显示添加子级的入口。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
