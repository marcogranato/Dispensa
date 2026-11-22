//
//  OrdinamentoElenchiTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct OrdinamentoElenchiTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa
    let frigo: Struttura
    let cantina: Struttura

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        cantina = Struttura(nome: "Cantina", tipo: .scaffale)
        container.mainContext.insert(frigo)
        container.mainContext.insert(cantina)
        frigo.dispensa = dispensa
        cantina.dispensa = dispensa
    }

    private func data(_ secondi: Double?) -> Date? {
        secondi.map { Date(timeIntervalSince1970: $0) }
    }

    @discardableResult
    private func articolo(
        _ nome: String,
        in struttura: Struttura? = nil,
        scadenza: Double? = nil,
        inserimento: Double = 0,
        uscita: Double? = nil
    ) -> Articolo {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        let articolo = Articolo()
        context.insert(articolo)
        articolo.prodotto = prodotto
        articolo.struttura = struttura
        articolo.dispensa = dispensa
        articolo.dataScadenza = data(scadenza)
        articolo.dataInserimento = Date(timeIntervalSince1970: inserimento)
        articolo.dataUscita = data(uscita)
        return articolo
    }

    private func nomi(_ articoli: [Articolo]) -> [String] {
        articoli.map(\.nomeVisualizzato)
    }

    // MARK: - Ordine e verso

    @Test func ordineInizialeComePrima() {
        let articoli = [
            articolo("Sale"),
            articolo("Pasta", scadenza: 2_000),
            articolo("Latte", scadenza: 1_000),
            articolo("Burro", scadenza: 1_000),
        ]
        #expect(nomi(OrdineArticoli.articoli.ordina(articoli)) == nomi(Articolo.ordinatiPerScadenza(articoli)))
        #expect(nomi(OrdineArticoli.articoli.ordina(articoli)) == ["Burro", "Latte", "Pasta", "Sale"])
    }

    @Test func cambiandoCriterioIlVersoTornaNaturale() {
        var ordine = OrdineArticoli.articoli
        #expect(ordine.crescente)
        ordine.crescente = false
        ordine.criterio = .nome
        #expect(ordine.crescente)
        ordine.criterio = .uscita
        #expect(!ordine.crescente)
        #expect(OrdineArticoli.storico.crescente == false)
        #expect(OrdineProdotti(.presenti).crescente == false)
        #expect(OrdineProdotti(.creazione).crescente == false)
    }

    @Test func scadenzaDecrescenteConDateMancantiInFondo() {
        let articoli = [
            articolo("Sale"),
            articolo("Latte", scadenza: 1_000),
            articolo("Pasta", scadenza: 2_000),
        ]
        var ordine = OrdineArticoli.articoli
        ordine.crescente = false
        #expect(nomi(ordine.ordina(articoli)) == ["Pasta", "Latte", "Sale"])
    }

    @Test func perNomeNeiDueVersi() {
        let articoli = [articolo("latte"), articolo("Vino"), articolo("Àcqua"), articolo("Latte 10"), articolo("Latte 2")]
        var ordine = OrdineArticoli(.nome)
        #expect(nomi(ordine.ordina(articoli)) == ["Àcqua", "latte", "Latte 2", "Latte 10", "Vino"])
        ordine.crescente = false
        #expect(nomi(ordine.ordina(articoli)) == ["Vino", "Latte 10", "Latte 2", "latte", "Àcqua"])
    }

    @Test func perNomeAParitaVinceLaScadenza() {
        let articoli = [
            articolo("Latte"),
            articolo("Latte", scadenza: 2_000),
            articolo("Latte", scadenza: 1_000),
        ]
        let ordinati = OrdineArticoli(.nome).ordina(articoli)
        #expect(ordinati.map(\.dataScadenza) == [data(1_000), data(2_000), nil])
    }

    @Test func perInserimento() {
        let articoli = [
            articolo("Vecchio", inserimento: 1_000),
            articolo("Recente", inserimento: 3_000),
            articolo("Medio", inserimento: 2_000),
        ]
        var ordine = OrdineArticoli(.inserimento)
        #expect(nomi(ordine.ordina(articoli)) == ["Vecchio", "Medio", "Recente"])
        ordine.crescente = false
        #expect(nomi(ordine.ordina(articoli)) == ["Recente", "Medio", "Vecchio"])
    }

    @Test func perStrutturaPoiScadenzaESenzaStrutturaInFondo() {
        let articoli = [
            articolo("Orfano"),
            articolo("Latte", in: frigo, scadenza: 2_000),
            articolo("Vino", in: cantina),
            articolo("Yogurt", in: frigo, scadenza: 1_000),
        ]
        var ordine = OrdineArticoli(.struttura)
        #expect(nomi(ordine.ordina(articoli)) == ["Vino", "Yogurt", "Latte", "Orfano"])
        ordine.crescente = false
        // Dentro la struttura resta l'ordine per scadenza; chi non ha struttura resta in fondo.
        #expect(nomi(ordine.ordina(articoli)) == ["Yogurt", "Latte", "Vino", "Orfano"])
    }

    @Test func perUscitaDallaPiuRecente() {
        let articoli = [
            articolo("Vecchio", uscita: 1_000),
            articolo("Senza data"),
            articolo("Recente", uscita: 3_000),
        ]
        var ordine = OrdineArticoli.storico
        #expect(nomi(ordine.ordina(articoli)) == ["Recente", "Vecchio", "Senza data"])
        ordine.crescente = true
        #expect(nomi(ordine.ordina(articoli)) == ["Vecchio", "Recente", "Senza data"])
    }

    // MARK: - Prodotti

    @discardableResult
    private func prodotto(_ nome: String, marca: String? = nil, creato: Double = 0, presenti: Int = 0) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        prodotto.marca = marca
        prodotto.dataCreazione = Date(timeIntervalSince1970: creato)
        for _ in 0..<presenti {
            let articolo = Articolo()
            context.insert(articolo)
            articolo.prodotto = prodotto
            articolo.struttura = frigo
            articolo.dispensa = dispensa
        }
        return prodotto
    }

    private func nomiProdotti(_ ordine: OrdineProdotti) -> [String] {
        dispensa.gruppiDiProdotti(ordine: ordine).flatMap(\.prodotti).map(\.nomeConMarca)
    }

    @Test func prodottiPerNomeEMarca() {
        prodotto("Penne", marca: "De Cecco")
        prodotto("Burro")
        prodotto("Penne", marca: "Barilla")
        var ordine = OrdineProdotti.prodotti
        let crescente = nomiProdotti(ordine)
        #expect(crescente.first == "Burro")
        #expect(crescente.count == 3)
        ordine.crescente = false
        #expect(nomiProdotti(ordine) == crescente.reversed())
    }

    @Test func prodottiPiuRecenti() {
        prodotto("Vecchio", creato: 1_000)
        prodotto("Recente", creato: 3_000)
        prodotto("Medio", creato: 2_000)
        #expect(nomiProdotti(OrdineProdotti(.creazione)) == ["Recente", "Medio", "Vecchio"])
    }

    @Test func prodottiPerArticoliPresentiAParitaPerNome() {
        prodotto("Zucchero", presenti: 1)
        prodotto("Latte", presenti: 3)
        prodotto("Burro", presenti: 1)
        prodotto("Sale")
        var ordine = OrdineProdotti(.presenti)
        #expect(nomiProdotti(ordine) == ["Latte", "Burro", "Zucchero", "Sale"])
        ordine.crescente = true
        #expect(nomiProdotti(ordine) == ["Sale", "Burro", "Zucchero", "Latte"])
    }

    @Test func ordineDentroOgniCategoria() throws {
        let bevande = try context.creaCategoria(nome: "Bevande", sotto: nil, in: dispensa)
        let acqua = prodotto("Acqua")
        let vino = prodotto("Vino")
        acqua.categoria = bevande
        vino.categoria = bevande
        prodotto("Burro")
        var ordine = OrdineProdotti.prodotti
        ordine.crescente = false
        let gruppi = dispensa.gruppiDiProdotti(ordine: ordine)
        // Le sezioni restano nello stesso ordine; cambia solo l'ordine dei prodotti al loro interno.
        #expect(gruppi.map { $0.categoria?.nome } == ["Bevande", nil])
        #expect(gruppi.first?.prodotti.map(\.nome) == ["Vino", "Acqua"])
    }
}
