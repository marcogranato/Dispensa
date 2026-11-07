//
//  DispensaApp.swift
//  Dispensa
//
//  Created by Marco Granato on 07/11/2026.
//

import SwiftUI
import SwiftData

@main
struct DispensaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = SchemaDispensa.schema
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
