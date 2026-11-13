//
//  GestioneCategorieTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneCategorieTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
    }

    /// "Pasta e riso ▸ Pasta secca ▸ Pasta di semola".
    private func creaAlberoPasta() throws -> (Categoria, Categoria, Categoria) {
        let pasta = try context.creaCategoria(nome: "Pasta e riso", icona: "🍝", sotto: nil, in: dispensa)
        let secca = try context.creaCategoria(nome: "Pasta secca", sotto: pasta, in: dispensa)
        let semola = try context.creaCategoria(nome: "Pasta di semola", sotto: secca, in: dispensa)
        return (pasta, secca, semola)
    }

    private func creaProdotto(_ nome: String, in categoria: Categoria?) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        prodotto.categoria = categoria
        return prodotto
    }

    @Test func creaUnAlberoDiTreLivelli() throws {
        let (pasta, secca, semola) = try creaAlberoPasta()

        #expect(dispensa.categoriePrincipali.map(\.id) == [pasta.id])
        #expect(dispensa.categorieInOrdine.map(\.nome) == ["Pasta e riso", "Pasta secca", "Pasta di semola"])
        #expect(secca.genitore === pasta)
        #expect(semola.livello == 3)
        #expect(pasta.altezza == 3)
        #expect(semola.altezza == 1)
        #expect(pasta.icona == "🍝")
    }

    @Test func rifiutaUnQuartoLivello() throws {
        let (_, _, semola) = try creaAlberoPasta()

        #expect(throws: ErroreGestioneCategorie.troppiLivelli) {
            try context.creaCategoria(nome: "Penne", sotto: semola, in: dispensa)
        }
    }

    @Test func rifiutaNomiVuotiODuplicatiAlloStessoLivello() throws {
        let (pasta, _, _) = try creaAlberoPasta()

        #expect(throws: ErroreGestioneCategorie.nomeVuoto) {
            try context.creaCategoria(nome: "   ", sotto: nil, in: dispensa)
        }
        #expect(throws: ErroreGestioneCategorie.nomeDuplicato) {
            try context.creaCategoria(nome: "pasta E RISO", sotto: nil, in: dispensa)
        }
        #expect(throws: ErroreGestioneCategorie.nomeDuplicato) {
            try context.creaCategoria(nome: "Pastà secca", sotto: pasta, in: dispensa)
        }
        // Lo stesso nome a un altro livello è ammesso.
        let altra = try context.creaCategoria(nome: " Pasta secca ", sotto: nil, in: dispensa)
        #expect(altra.nome == "Pasta secca")
    }

    @Test func spostaUnaCategoriaConLeSueSottocategorie() throws {
        let (pasta, secca, semola) = try creaAlberoPasta()
        let cereali = try context.creaCategoria(nome: "Cereali", sotto: nil, in: dispensa)

        try context.modificaCategoria(secca, nome: "Pasta secca", icona: nil, sotto: cereali)

        #expect(secca.genitore === cereali)
        #expect(semola.percorso.map(\.nome) == ["Cereali", "Pasta secca", "Pasta di semola"])
        #expect(pasta.sottocategorie?.isEmpty ?? true)
    }

    @Test func rifiutaSpostamentiCircolariOTroppoProfondi() throws {
        let (pasta, secca, semola) = try creaAlberoPasta()
        let riso = try context.creaCategoria(nome: "Riso", sotto: pasta, in: dispensa)

        #expect(throws: ErroreGestioneCategorie.spostamentoCircolare) {
            try context.modificaCategoria(pasta, nome: "Pasta e riso", icona: nil, sotto: semola)
        }
        #expect(throws: ErroreGestioneCategorie.spostamentoCircolare) {
            try context.modificaCategoria(secca, nome: "Pasta secca", icona: nil, sotto: secca)
        }
        // "Pasta secca" ha due livelli: sotto "Riso" (livello 2) diventerebbero quattro.
        #expect(throws: ErroreGestioneCategorie.troppiLivelli) {
            try context.modificaCategoria(secca, nome: "Pasta secca", icona: nil, sotto: riso)
        }
        #expect(secca.genitore === pasta)
    }

    @Test func rinominaSenzaConsiderarsiUnDuplicato() throws {
        let (_, secca, _) = try creaAlberoPasta()

        try context.modificaCategoria(secca, nome: "PASTA SECCA", icona: "🌾", sotto: secca.genitore)

        #expect(secca.nome == "PASTA SECCA")
        #expect(secca.icona == "🌾")
    }

    @Test func eliminaLeSottocategorieESpostaIProdottiAlGenitore() throws {
        let (pasta, secca, semola) = try creaAlberoPasta()
        let penne = creaProdotto("Penne rigate", in: semola)
        let spaghetti = creaProdotto("Spaghetti", in: secca)
        let riso = creaProdotto("Riso Carnaroli", in: pasta)
        try context.save()

        context.eliminaCategoria(secca)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Categoria>()).map(\.nome) == ["Pasta e riso"])
        #expect(penne.categoria === pasta)
        #expect(spaghetti.categoria === pasta)
        #expect(riso.categoria === pasta)
        #expect(try context.fetchCount(FetchDescriptor<Prodotto>()) == 3)
    }

    @Test func eliminaUnaCategoriaPrincipaleLasciandoIProdottiSenzaCategoria() throws {
        let (pasta, _, semola) = try creaAlberoPasta()
        let penne = creaProdotto("Penne rigate", in: semola)
        try context.save()

        context.eliminaCategoria(pasta)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Categoria>()) == 0)
        #expect(penne.categoria == nil)
        #expect(try context.fetchCount(FetchDescriptor<Prodotto>()) == 1)
    }

    @Test func iconaRidottaAUnSoloCarattere() {
        #expect(Categoria.iconaNormalizzata(nil) == nil)
        #expect(Categoria.iconaNormalizzata("  ") == nil)
        #expect(Categoria.iconaNormalizzata(" 🍝🍚") == "🍝")
        #expect(Categoria.iconaNormalizzata("👨‍👩‍👧") == "👨‍👩‍👧")
    }
}
