//
//  SupportoTest.swift
//  DispensaTests
//

import SwiftData
@testable import Dispensa

/// Database vuoto in memoria, diverso per ogni test.
@MainActor
func creaContainerDiTest() throws -> ModelContainer {
    let configurazione = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: SchemaDispensa.schema, configurations: [configurazione])
}
