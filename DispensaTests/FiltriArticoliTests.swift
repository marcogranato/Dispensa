//
//  FiltriArticoliTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct FiltriArticoliTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa
    let frigo: Struttura
    let scaffale: Struttura
    let calendario = Calendar(identifier: .gregorian)
    /// Un "oggi" fisso: i test non dipendono dal giorno in cui girano.
    let oggi: Date

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        scaffale = Struttura(nome: "Scaffale", tipo: .scaffale)
        container.mainContext.insert(frigo)
        container.mainContext.insert(scaffale)
        frigo.dispensa = dispensa
        scaffale.dispensa = dispensa
        oggi = calendario.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12))!
    }

    private func giorno(_ differenza: Int, ora: Int = 12) -> Date {
        let base = calendario.date(byAdding: .day, value: differenza, to: oggi)!
        return calendario.date(bySettingHour: ora, minute: 0, second: 0, of: base)!
    }

    @discardableResult
    private func articolo(
        _ nome: String,
        in struttura: Struttura?,
        categoria: Categoria? = nil,
        etichette: [Etichetta] = [],
        scadenza: Int? = nil
    ) -> Articolo {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        prodotto.categoria = categoria
        prodotto.etichette = etichette
        let articolo = Articolo()
        context.insert(articolo)
        articolo.prodotto = prodotto
        articolo.struttura = struttura
        articolo.dispensa = dispensa
        articolo.dataInserimento = giorno(-10)
        articolo.dataScadenza = scadenza.map { giorno($0) }
        return articolo
    }

    private func nomi(_ filtro: FiltroArticoli, _ articoli: [Articolo]) -> [String] {
        filtro.applica(articoli, oggi: oggi, calendario: calendario).map(\.nomeVisualizzato)
    }

    @Test func senzaFiltriPassaTutto() {
        let tutti = [articolo("Latte", in: frigo), articolo("Pasta", in: nil)]
        let filtro = FiltroArticoli()

        #expect(filtro.vuoto)
        #expect(filtro.numeroAttivi == 0)
        #expect(nomi(filtro, tutti) == ["Latte", "Pasta"])
    }

    @Test func struttureETipiDiStruttura() {
        let tutti = [articolo("Latte", in: frigo), articolo("Pasta", in: scaffale), articolo("Orfano", in: nil)]

        var filtro = FiltroArticoli()
        filtro.strutture = [frigo.id, scaffale.id]
        #expect(nomi(filtro, tutti) == ["Latte", "Pasta"])

        filtro = FiltroArticoli()
        filtro.tipiStruttura = [.scaffale]
        #expect(nomi(filtro, tutti) == ["Pasta"])
    }

    @Test func laCategoriaComprendeLeSottocategorie() throws {
        let pasta = try context.creaCategoria(nome: "Pasta e riso", sotto: nil, in: dispensa)
        let secca = try context.creaCategoria(nome: "Pasta secca", sotto: pasta, in: dispensa)
        let latticini = try context.creaCategoria(nome: "Latticini", sotto: nil, in: dispensa)
        let tutti = [
            articolo("Penne", in: scaffale, categoria: secca),
            articolo("Riso", in: scaffale, categoria: pasta),
            articolo("Latte", in: frigo, categoria: latticini),
            articolo("Sale", in: scaffale),
        ]

        var filtro = FiltroArticoli()
        filtro.categorie = [pasta.id]
        #expect(nomi(filtro, tutti) == ["Penne", "Riso"])

        filtro.categorie = [secca.id]
        #expect(nomi(filtro, tutti) == ["Penne"])
    }

    @Test func etichetteUnaQualsiasi() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", in: dispensa)
        let bio = try context.creaEtichetta(nome: "bio", in: dispensa)
        let tutti = [
            articolo("Latte", in: frigo, etichette: [colazione]),
            articolo("Mele", in: frigo, etichette: [bio]),
            articolo("Sale", in: scaffale),
        ]

        var filtro = FiltroArticoli()
        filtro.etichette = [colazione.id, bio.id]
        #expect(nomi(filtro, tutti) == ["Latte", "Mele"])
    }

    @Test func statoDellaScadenza() {
        let tutti = [
            articolo("Scaduto", in: frigo, scadenza: -1),
            articolo("Oggi", in: frigo, scadenza: 0),
            articolo("Lontano", in: frigo, scadenza: 30),
            articolo("Senza", in: frigo),
        ]

        var filtro = FiltroArticoli()
        filtro.scadenze = [.scaduto, .inScadenza]
        #expect(nomi(filtro, tutti) == ["Scaduto", "Oggi"])

        filtro.scadenze = [.senzaScadenza]
        #expect(nomi(filtro, tutti) == ["Senza"])
    }

    @Test func intervalliDiDateConEstremiCompresiESoloGiorni() {
        let tutti = [
            articolo("Ieri", in: frigo, scadenza: -1),
            articolo("Oggi", in: frigo, scadenza: 0),
            articolo("Fra5", in: frigo, scadenza: 5),
            articolo("Fra6", in: frigo, scadenza: 6),
            articolo("Senza", in: frigo),
        ]

        var filtro = FiltroArticoli()
        // Estremi con un'ora diversa da quella delle scadenze: contano solo i giorni.
        filtro.scadenza = IntervalloDate(dal: giorno(0, ora: 23), al: giorno(5, ora: 1))
        #expect(nomi(filtro, tutti) == ["Oggi", "Fra5"])

        filtro.scadenza = IntervalloDate(dal: nil, al: giorno(0))
        #expect(nomi(filtro, tutti) == ["Ieri", "Oggi"])

        // La data di produzione manca a tutti: con l'intervallo impostato nessuno passa.
        filtro = FiltroArticoli()
        filtro.produzione = IntervalloDate(dal: giorno(-100), al: nil)
        #expect(nomi(filtro, tutti).isEmpty)

        filtro = FiltroArticoli()
        filtro.inserimento = IntervalloDate(dal: giorno(-10), al: giorno(-10))
        #expect(nomi(filtro, tutti).count == 5)
    }

    @Test func gruppiDiversiDevonoValereTutti() {
        let tutti = [
            articolo("LatteScaduto", in: frigo, scadenza: -2),
            articolo("LatteBuono", in: frigo, scadenza: 20),
            articolo("PastaScaduta", in: scaffale, scadenza: -2),
        ]

        var filtro = FiltroArticoli()
        filtro.strutture = [frigo.id]
        filtro.scadenze = [.scaduto]
        filtro.scadenza = IntervalloDate(dal: giorno(-5), al: nil)

        #expect(filtro.numeroAttivi == 3)
        #expect(nomi(filtro, tutti) == ["LatteScaduto"])
    }

    @Test func esitoEDataDiUscitaNelloStorico() {
        let consumato = articolo("Consumato", in: frigo)
        consumato.stato = .consumato
        consumato.dataUscita = giorno(-1)
        let buttato = articolo("Buttato", in: frigo)
        buttato.stato = .buttato
        buttato.dataUscita = giorno(-20)
        let tutti = [consumato, buttato]

        var filtro = FiltroArticoli()
        filtro.esiti = [.buttato]
        #expect(nomi(filtro, tutti) == ["Buttato"])

        filtro = FiltroArticoli()
        filtro.uscita = IntervalloDate(dal: giorno(-7), al: nil)
        #expect(nomi(filtro, tutti) == ["Consumato"])
    }
}
