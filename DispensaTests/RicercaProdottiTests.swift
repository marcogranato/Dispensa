//
//  RicercaProdottiTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct RicercaProdottiTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
    }

    @discardableResult
    private func creaProdotto(_ nome: String, marca: String? = nil, codice: String? = nil, in categoria: Categoria? = nil) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        prodotto.marca = marca
        prodotto.codiceBarre = codice
        prodotto.categoria = categoria
        return prodotto
    }

    /// "Pasta e riso ▸ Pasta secca ▸ Pasta di semola" e "Latticini".
    private func creaCategorie() throws -> (pasta: Categoria, secca: Categoria, semola: Categoria, latticini: Categoria) {
        let pasta = try context.creaCategoria(nome: "Pasta e riso", sotto: nil, in: dispensa)
        let secca = try context.creaCategoria(nome: "Pasta secca", sotto: pasta, in: dispensa)
        let semola = try context.creaCategoria(nome: "Pasta di semola", sotto: secca, in: dispensa)
        let latticini = try context.creaCategoria(nome: "Latticini", sotto: nil, in: dispensa)
        return (pasta, secca, semola, latticini)
    }

    @Test func gruppiPerCategoriaPrincipaleConSenzaCategoriaInFondo() throws {
        let c = try creaCategorie()
        _ = try context.creaCategoria(nome: "Bevande", sotto: nil, in: dispensa) // vuota: non compare
        creaProdotto("Sale")
        creaProdotto("Penne", in: c.semola)
        creaProdotto("Riso", in: c.pasta)
        creaProdotto("Latte", in: c.latticini)

        let gruppi = dispensa.gruppiDiProdotti()

        #expect(gruppi.map { $0.categoria?.nome } == ["Latticini", "Pasta e riso", nil])
        #expect(gruppi[1].prodotti.map(\.nome) == ["Penne", "Riso"])
        #expect(gruppi[2].prodotti.map(\.nome) == ["Sale"])
    }

    @Test func prodottiOrdinatiPerNomeEPoiPerMarca() {
        creaProdotto("Penne", marca: "De Cecco")
        creaProdotto("Biscotti")
        creaProdotto("Penne", marca: "Barilla")
        creaProdotto("Penne")

        let prodotti = dispensa.gruppiDiProdotti().flatMap(\.prodotti)

        #expect(prodotti.map(\.nomeConMarca) == ["Biscotti", "Penne", "Penne · Barilla", "Penne · De Cecco"])
    }

    @Test func laCategoriaPrincipaleTrovaAncheLeSottocategorie() throws {
        let c = try creaCategorie()
        creaProdotto("Penne", in: c.semola)
        creaProdotto("Fusilli", in: c.secca)
        creaProdotto("Latte", in: c.latticini)

        let gruppi = dispensa.gruppiDiProdotti(cercando: "riso")

        #expect(gruppi.count == 1)
        #expect(gruppi.first?.categoria === c.pasta)
        #expect(gruppi.first?.prodotti.map(\.nome) == ["Fusilli", "Penne"])
    }

    @Test func laSottocategoriaTrovaSoloISuoiProdotti() throws {
        let c = try creaCategorie()
        creaProdotto("Penne", in: c.semola)
        creaProdotto("Fusilli", in: c.secca)

        #expect(dispensa.gruppiDiProdotti(cercando: "semola").flatMap(\.prodotti).map(\.nome) == ["Penne"])
    }

    @Test func cercaPerNomeMarcaECodiceSenzaBadareAMaiuscoleEAccenti() {
        creaProdotto("Caffè", marca: "Lavazza")
        creaProdotto("Penne", marca: "Barilla", codice: "8076802085738")

        func nomi(_ testo: String) -> [String] {
            dispensa.gruppiDiProdotti(cercando: testo).flatMap(\.prodotti).map(\.nome)
        }
        #expect(nomi("CAFFE") == ["Caffè"])
        #expect(nomi("barilla") == ["Penne"])
        #expect(nomi("8076802085738") == ["Penne"])
        #expect(nomi("80768") == []) // il codice va scritto per intero
        #expect(nomi("  ") == ["Caffè", "Penne"])
    }

    @Test func percorsoSottoLaCategoriaPrincipale() throws {
        let c = try creaCategorie()
        let penne = creaProdotto("Penne", in: c.semola)
        let riso = creaProdotto("Riso", in: c.pasta)
        let sale = creaProdotto("Sale")

        #expect(penne.categoriaPrincipale === c.pasta)
        #expect(penne.percorsoSottocategoria == "Pasta secca ▸ Pasta di semola")
        #expect(riso.percorsoSottocategoria == nil)
        #expect(sale.categoriaPrincipale == nil)
        #expect(sale.percorsoSottocategoria == nil)
    }
}
