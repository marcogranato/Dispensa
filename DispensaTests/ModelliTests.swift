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
        container = try creaContainerDiTest()
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

    @Test func ordinamentoPerScadenza() {
        func articolo(_ nome: String, scadenza: TimeInterval?) -> Articolo {
            let prodotto = Prodotto(nome: nome)
            let articolo = Articolo()
            context.insert(prodotto)
            context.insert(articolo)
            articolo.prodotto = prodotto
            articolo.dataScadenza = scadenza.map { Date(timeIntervalSince1970: $0) }
            return articolo
        }
        let senzaDataB = articolo("Sale", scadenza: nil)
        let tardi = articolo("Pasta", scadenza: 2_000)
        let senzaDataA = articolo("Riso", scadenza: nil)
        let presto = articolo("Latte", scadenza: 1_000)
        let prestoA = articolo("Burro", scadenza: 1_000)

        let ordinati = Articolo.ordinatiPerScadenza([senzaDataB, tardi, senzaDataA, presto, prestoA])

        #expect(ordinati.map(\.nomeVisualizzato) == ["Burro", "Latte", "Pasta", "Riso", "Sale"])
    }

    @Test func storicoDalPiuRecente() throws {
        let (dispensa, _, presente) = try creaDispensaConArticolo()
        let vecchio = Articolo()
        let recente = Articolo()
        for articolo in [vecchio, recente] {
            context.insert(articolo)
            articolo.dispensa = dispensa
            articolo.stato = .consumato
        }
        vecchio.dataUscita = Date(timeIntervalSince1970: 1_000)
        recente.dataUscita = Date(timeIntervalSince1970: 2_000)

        let storico = dispensa.articoliNelloStorico

        #expect(storico.map(\.id) == [recente.id, vecchio.id])
        #expect(!storico.contains { $0 === presente })
    }

    @Test func articoliAttiviEscludonoLoStorico() throws {
        let (_, struttura, articolo) = try creaDispensaConArticolo()
        #expect(struttura.articoliAttivi.count == 1)

        articolo.stato = .consumato
        #expect(struttura.articoliAttivi.isEmpty)
    }

    // MARK: - Categorie e dettagli del prodotto

    /// Crea l'albero "Pasta e riso ▸ Pasta secca ▸ Pasta di semola" in una dispensa.
    private func creaAlberoPasta() -> (Categoria, Categoria, Categoria) {
        let dispensa = Dispensa(nome: "Casa")
        let pasta = Categoria(nome: "Pasta e riso")
        let secca = Categoria(nome: "Pasta secca")
        let semola = Categoria(nome: "Pasta di semola")
        context.insert(dispensa)
        for categoria in [pasta, secca, semola] {
            context.insert(categoria)
            categoria.dispensa = dispensa
        }
        secca.genitore = pasta
        semola.genitore = secca
        return (pasta, secca, semola)
    }

    @Test func percorsoELivelloDellaCategoria() {
        let (pasta, secca, semola) = creaAlberoPasta()

        #expect(semola.percorso.map(\.nome) == ["Pasta e riso", "Pasta secca", "Pasta di semola"])
        #expect(pasta.livello == 1)
        #expect(secca.livello == 2)
        #expect(semola.livello == 3)
        #expect(Set(pasta.discendenti.map(\.id)) == [secca.id, semola.id])
        #expect(semola.discendenti.isEmpty)
    }

    @Test func iconaEreditataDalGenitorePiuVicino() {
        let (pasta, secca, semola) = creaAlberoPasta()
        pasta.icona = "🍝"
        #expect(semola.iconaEffettiva == "🍝")

        secca.icona = "🌾"
        #expect(semola.iconaEffettiva == "🌾")

        let prodotto = Prodotto(nome: "Penne rigate")
        context.insert(prodotto)
        prodotto.categoria = semola
        #expect(prodotto.iconaEffettiva == "🌾")

        prodotto.icona = "🥣"
        #expect(prodotto.iconaEffettiva == "🥣")

        prodotto.icona = " "
        prodotto.categoria = nil
        #expect(prodotto.iconaEffettiva == nil)
    }

    @Test func quantitaTotaleEMultipack() {
        let biscotti = Prodotto(nome: "Oro Saiwa")
        #expect(biscotti.quantitaTotale == nil)
        #expect(!biscotti.isMultipack)

        biscotti.quantitaPerParte = 100
        biscotti.partiPerConfezione = 4
        biscotti.tipoParte = .pacchetto
        #expect(biscotti.quantitaTotale == 400)
        #expect(biscotti.isMultipack)
        #expect(biscotti.tipoParteRaw == "pacchetto")

        biscotti.tipoParteRaw = "valore sconosciuto"
        #expect(biscotti.tipoParte == nil)
    }

    @Test func eliminareCategoriaLasciaIProdotti() throws {
        let (pasta, _, _) = creaAlberoPasta()
        let prodotto = Prodotto(nome: "Penne rigate")
        context.insert(prodotto)
        prodotto.categoria = pasta
        try context.save()

        context.delete(pasta)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Prodotto>()) == 1)
        #expect(prodotto.categoria == nil)
    }
}
