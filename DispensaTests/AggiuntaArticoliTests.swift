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

    // MARK: - Nome e marca

    private func creaProdotto(_ nome: String, marca: String? = nil) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        prodotto.marca = marca
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        return prodotto
    }

    @Test func ilProdottoSiRiconosceDaNomeEMarca() {
        let barilla = creaProdotto("Penne rigate", marca: "Barilla")
        let senzaMarca = creaProdotto("Penne rigate")

        #expect(context.trovaOCreaProdotto(nominato: "penne RIGATE", marca: " barilla ", in: dispensa, dati: DatiArticolo()) === barilla)
        #expect(context.trovaOCreaProdotto(nominato: "Penne rigate", marca: "", in: dispensa, dati: DatiArticolo()) === senzaMarca)
        #expect(context.trovaOCreaProdotto(nominato: "Penne rigate", in: dispensa, dati: DatiArticolo()) === senzaMarca)

        let deCecco = context.trovaOCreaProdotto(nominato: "Penne rigate", marca: " De Cecco ", in: dispensa, dati: DatiArticolo())
        #expect(deCecco !== barilla && deCecco !== senzaMarca)
        #expect(deCecco.marca == "De Cecco")
        #expect(dispensa.prodotti?.count == 3)
    }

    @Test func ilProdottoNuovoPrendeCategoriaTipoDiParteEdEmoji() throws {
        let pasta = try context.creaCategoria(nome: "Pasta secca", sotto: nil, in: dispensa)
        let barilla = creaProdotto("Penne rigate", marca: "Barilla")
        barilla.icona = "🍝"
        var dati = DatiArticolo()
        dati.partiTotali = 2

        let deCecco = context.trovaOCreaProdotto(
            nominato: "Penne rigate", marca: "De Cecco", in: dispensa, dati: dati,
            categoria: pasta, tipoParte: .pacchetto
        )

        #expect(deCecco.categoria === pasta)
        #expect(deCecco.tipoParte == .pacchetto)
        #expect(deCecco.icona == "🍝")
    }

    @Test func ilTipoDiParteSiIgnoraPerUnaParteSola() {
        let prodotto = context.trovaOCreaProdotto(nominato: "Latte", in: dispensa, dati: DatiArticolo(), tipoParte: .bottiglia)
        #expect(prodotto.tipoParte == nil)
    }

    @Test func lOmonimoPreferitoEQuelloClassificato() throws {
        let pasta = try context.creaCategoria(nome: "Pasta secca", sotto: nil, in: dispensa)
        _ = creaProdotto("Penne rigate", marca: "Rummo")
        let classificato = creaProdotto("Penne rigate", marca: "Barilla")
        classificato.categoria = pasta

        #expect(dispensa.prodottoOmonimo(nominato: "penne rigate") === classificato)
        #expect(dispensa.prodottoOmonimo(nominato: "Fusilli") == nil)
    }

    @Test func nomeConMarca() {
        #expect(creaProdotto("Penne rigate", marca: "Barilla").nomeConMarca == "Penne rigate · Barilla")
        #expect(creaProdotto("Latte").nomeConMarca == "Latte")
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
