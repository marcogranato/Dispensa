//
//  FiltriProdottiTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct FiltriProdottiTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa
    let frigo: Struttura

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        container.mainContext.insert(frigo)
        frigo.dispensa = dispensa
    }

    @discardableResult
    private func prodotto(
        _ nome: String,
        categoria: Categoria? = nil,
        etichette: [Etichetta] = [],
        presenti: Int = 0,
        usciti: Int = 0
    ) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        prodotto.categoria = categoria
        prodotto.etichette = etichette
        for indice in 0..<(presenti + usciti) {
            let articolo = Articolo()
            context.insert(articolo)
            articolo.prodotto = prodotto
            articolo.dispensa = dispensa
            if indice < presenti {
                articolo.struttura = frigo
            } else {
                articolo.stato = .consumato
            }
        }
        return prodotto
    }

    private func nomi(_ filtro: FiltroProdotti) -> [String] {
        dispensa.gruppiDiProdotti(filtro: filtro).flatMap(\.prodotti).map(\.nome).sorted()
    }

    @Test func filtroVuotoTrovaTutto() {
        prodotto("Latte")
        prodotto("Sale")
        let filtro = FiltroProdotti()
        #expect(filtro.vuoto)
        #expect(filtro.numeroAttivi == 0)
        #expect(nomi(filtro) == ["Latte", "Sale"])
    }

    @Test func categoriaComprendeLeSottocategorie() throws {
        let pasta = try context.creaCategoria(nome: "Pasta", sotto: nil, in: dispensa)
        let secca = try context.creaCategoria(nome: "Pasta secca", sotto: pasta, in: dispensa)
        let bevande = try context.creaCategoria(nome: "Bevande", sotto: nil, in: dispensa)
        prodotto("Penne", categoria: secca)
        prodotto("Lasagne", categoria: pasta)
        prodotto("Vino", categoria: bevande)
        prodotto("Sale")

        #expect(nomi(FiltroProdotti(categorie: [pasta.id])) == ["Lasagne", "Penne"])
        #expect(nomi(FiltroProdotti(categorie: [secca.id])) == ["Penne"])
        // Dentro un gruppo basta una delle scelte.
        #expect(nomi(FiltroProdotti(categorie: [secca.id, bevande.id])) == ["Penne", "Vino"])
    }

    @Test func perEtichetta() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", in: dispensa)
        let bio = try context.creaEtichetta(nome: "bio", in: dispensa)
        prodotto("Biscotti", etichette: [colazione])
        prodotto("Latte", etichette: [colazione, bio])
        prodotto("Sale")

        #expect(nomi(FiltroProdotti(etichette: [bio.id])) == ["Latte"])
        #expect(nomi(FiltroProdotti(etichette: [colazione.id])) == ["Biscotti", "Latte"])
    }

    @Test func conOSenzaArticoliPresenti() {
        prodotto("Latte", presenti: 2)
        // Un articolo nello storico non conta come presente.
        prodotto("Burro", usciti: 1)
        prodotto("Sale")

        #expect(nomi(FiltroProdotti(presenze: [.conArticoli])) == ["Latte"])
        #expect(nomi(FiltroProdotti(presenze: [.senzaArticoli])) == ["Burro", "Sale"])
        #expect(nomi(FiltroProdotti(presenze: [.conArticoli, .senzaArticoli])) == ["Burro", "Latte", "Sale"])
    }

    @Test func traGruppiDevonoValereTutti() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", in: dispensa)
        prodotto("Biscotti", etichette: [colazione], presenti: 1)
        prodotto("Fette biscottate", etichette: [colazione])
        prodotto("Sale")

        let filtro = FiltroProdotti(etichette: [colazione.id], presenze: [.senzaArticoli])
        #expect(filtro.numeroAttivi == 2)
        #expect(nomi(filtro) == ["Fette biscottate"])
    }

    @Test func iGruppiSenzaProdottiSpariscono() throws {
        let bevande = try context.creaCategoria(nome: "Bevande", sotto: nil, in: dispensa)
        prodotto("Vino", categoria: bevande)
        prodotto("Sale", presenti: 1)

        let gruppi = dispensa.gruppiDiProdotti(filtro: FiltroProdotti(presenze: [.conArticoli]))
        #expect(gruppi.count == 1)
        #expect(gruppi.first?.categoria == nil)
        #expect(gruppi.first?.prodotti.map(\.nome) == ["Sale"])
    }

    @Test func filtroERicercaInsieme() throws {
        prodotto("Latte intero", presenti: 1)
        prodotto("Latte scremato")
        let trovati = dispensa.gruppiDiProdotti(cercando: "latte", filtro: FiltroProdotti(presenze: [.senzaArticoli]))
        #expect(trovati.flatMap(\.prodotti).map(\.nome) == ["Latte scremato"])
    }
}
