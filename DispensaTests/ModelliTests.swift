//
//  ModelliTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct ModelliTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        let configurazione = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SchemaDispensa.schema, configurations: [configurazione])
    }

    /// Crea una dispensa con una struttura che contiene un articolo.
    private func creaDispensaConArticolo() throws -> (Dispensa, Struttura, Articolo) {
        let dispensa = Dispensa(nome: "Casa")
        let struttura = Struttura(nome: "Frigo", tipo: .frigorifero)
        let articolo = Articolo(partiTotali: 6)
        context.insert(dispensa)
        context.insert(struttura)
        context.insert(articolo)
        struttura.dispensa = dispensa
        articolo.dispensa = dispensa
        articolo.struttura = struttura
        try context.save()
        return (dispensa, struttura, articolo)
    }

    @Test func valoriPredefiniti() {
        let dispensa = Dispensa(nome: "Casa")
        #expect(dispensa.storicoAbilitato)

        let articolo = Articolo(partiTotali: 6)
        #expect(articolo.partiRimaste == 6)
        #expect(articolo.partiButtate == 0)
        #expect(articolo.stato == .attivo)
        #expect(articolo.motivoScarto == nil)
        #expect(articolo.dataScadenza == nil)

        let struttura = Struttura(nome: "Frigo", tipo: .frigorifero)
        #expect(struttura.tipo == .frigorifero)
    }

    @Test func enumSalvatiComeTesto() {
        let articolo = Articolo()
        articolo.stato = .buttato
        articolo.motivoScarto = .scaduto
        #expect(articolo.statoRaw == "buttato")
        #expect(articolo.motivoScartoRaw == "scaduto")

        let struttura = Struttura(nome: "X", tipo: .scaffale)
        struttura.tipoRaw = "valore sconosciuto"
        #expect(struttura.tipo == .altro)
    }

    @Test func eliminareDispensaEliminaIlContenuto() throws {
        let (dispensa, _, _) = try creaDispensaConArticolo()

        context.delete(dispensa)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Struttura>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Articolo>()) == 0)
    }

    @Test func eliminareStrutturaConservaGliArticoli() throws {
        let (dispensa, struttura, articolo) = try creaDispensaConArticolo()

        context.delete(struttura)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Articolo>()) == 1)
        #expect(articolo.struttura == nil)
        #expect(articolo.dispensa === dispensa)
    }

    @Test func articoliAttiviEscludonoLoStorico() throws {
        let (_, struttura, articolo) = try creaDispensaConArticolo()
        #expect(struttura.articoliAttivi.count == 1)

        articolo.stato = .consumato
        #expect(struttura.articoliAttivi.isEmpty)
    }
}
