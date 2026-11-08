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
        // I test UI avviano l'app con "--in-memoria" per non toccare i dati reali.
        let inMemoria = ProcessInfo.processInfo.arguments.contains("--in-memoria")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemoria)

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
