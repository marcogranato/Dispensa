//
//  GestioneStruttureTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneStruttureTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        let configurazione = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SchemaDispensa.schema, configurations: [configurazione])
    }

    @Test func eliminaStrutturaEliminaSoloGliArticoliAttivi() throws {
        let dispensa = Dispensa(nome: "Casa")
        let struttura = Struttura(nome: "Frigo", tipo: .frigorifero)
        let attivo = Articolo()
        let consumato = Articolo()
        context.insert(dispensa)
        context.insert(struttura)
        context.insert(attivo)
        context.insert(consumato)
        struttura.dispensa = dispensa
        for articolo in [attivo, consumato] {
            articolo.dispensa = dispensa
            articolo.struttura = struttura
        }
        consumato.stato = .consumato
        try context.save()

        context.eliminaStruttura(struttura)
        try context.save()

        let rimasti = try context.fetch(FetchDescriptor<Articolo>())
        #expect(rimasti.count == 1)
        #expect(rimasti.first?.stato == .consumato)
        #expect(rimasti.first?.struttura == nil)
        #expect(try context.fetchCount(FetchDescriptor<Struttura>()) == 0)
    }

    @Test func nomeTipoUsaIlNomePersonalizzatoSoloPerAltro() {
        let struttura = Struttura(nome: "Mobile", tipo: .altro)
        struttura.tipoPersonalizzato = "Credenza"
        #expect(struttura.nomeTipo == "Credenza")

        struttura.tipo = .scaffale
        #expect(struttura.nomeTipo == String(localized: TipoStruttura.scaffale.nomeLocalizzato))
    }
}
