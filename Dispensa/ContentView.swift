//
//  ContentView.swift
//  Dispensa
//
//  Created by Marco Granato on 07/11/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ContentUnavailableView("Dispensa", systemImage: "cabinet", description: Text("Interfaccia in costruzione."))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SchemaDispensa.modelli, inMemory: true)
}
