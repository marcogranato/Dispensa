//
//  AggiuntaArticoliTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct AggiuntaArticoliTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    let dispensa: Dispensa
    let frigo: Struttura

    init() throws {
        container = try creaContainerDiTest()
        let context = container.mainContext
        dispensa = Dispensa(nome: "Casa")
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        context.insert(dispensa)
        context.insert(frigo)
        frigo.dispensa = dispensa
    }

    @Test func datiPropostiDalProdotto() {
        let prodotto = Prodotto(nome: "Biscotti")
        prodotto.partiPerConfezione = 6
        prodotto.quantitaPerParte = 150
        prodotto.unita = .grammi

        let dati = DatiArticolo(prodotto: prodotto)

        #expect(dati.partiTotali == 6)
        #expect(dati.quantitaPerParte == 150)
        #expect(dati.unita == .grammi)
        #expect(dati.dataScadenza == nil)
    }

    @Test func trovaIlProdottoIgnorandoMaiuscoleEAccenti() {
        let caffe = Prodotto(nome: "Caffè")
        context.insert(caffe)
        caffe.dispensa = dispensa

        let trovato = context.trovaOCreaProdotto(nominato: " caffe ", in: dispensa, dati: DatiArticolo())

        #expect(trovato === caffe)
        #expect(dispensa.prodotti?.count == 1)
    }

    @Test func creaIlProdottoSeNonEsiste() {
        var dati = DatiArticolo()
        dati.partiTotali = 4
        dati.quantitaPerParte = 125
        dati.unita = .grammi

        let prodotto = context.trovaOCreaProdotto(nominato: "  Yogurt ", in: dispensa, dati: dati)

        #expect(prodotto.nome == "Yogurt")
        #expect(prodotto.dispensa === dispensa)
        #expect(prodotto.partiPerConfezione == 4)
        #expect(prodotto.quantitaPerParte == 125)
        #expect(prodotto.unita == .grammi)
    }

    @Test func aggiungeConfezioniUguali() throws {
        let prodotto = Prodotto(nome: "Latte")
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        var dati = DatiArticolo()
        dati.quantitaPerParte = 1
        dati.unita = .litri
        dati.dataScadenza = Date(timeIntervalSince1970: 2_000_000_000)

        let articoli = context.aggiungiArticoli(dati, prodotto: prodotto, struttura: frigo, confezioni: 3)
        try context.save()

        #expect(articoli.count == 3)
        #expect(frigo.articoliAttivi.count == 3)
        for articolo in articoli {
            #expect(articolo.prodotto === prodotto)
            #expect(articolo.dispensa === dispensa)
            #expect(articolo.partiRimaste == 1)
            #expect(articolo.unita == .litri)
            #expect(articolo.dataScadenza == dati.dataScadenza)
        }
    }

    @Test func ridurreLePartiTotaliLimitaLePartiRimaste() {
        let articolo = Articolo(partiTotali: 6)
        var dati = DatiArticolo(articolo: articolo)
        dati.partiTotali = 4

        dati.applica(a: articolo)

        #expect(articolo.partiTotali == 4)
        #expect(articolo.partiRimaste == 4)
    }
}
