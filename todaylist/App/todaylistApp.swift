//
//  todaylistApp.swift
//  todaylist
//
//  Created by 尹星 on 2025/11/20.
//

import SwiftUI
import SwiftData

@main
struct todaylistApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(SchemaV2.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, migrationPlan: DataMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }

        MenuBarExtra("TodayList", systemImage: "checklist") {
            Button("Settings") {
                NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
