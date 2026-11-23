//
//  TabelleTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import SwiftUI
import Testing
@testable import Dispensa

@MainActor
struct TabelleTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try creaContainerDiTest()
    }

    // MARK: - Intestazioni e ordine

    @Test func lIntestazioneParteDalVersoNaturale() {
        #expect(ComparatoreArticoli(.nome).order == .forward)
        #expect(ComparatoreArticoli(.uscita).order == .reverse)
        #expect(ComparatoreProdotti(.presenti).order == .reverse)
        #expect(ComparatoreArticoli(.uscita).ordine == OrdineArticoli.storico)
    }

    @Test func ordineEComparatoreSiCorrispondono() {
        var ordine = OrdineArticoli(.scadenza)
        ordine.crescente = false
        let comparatore = ComparatoreArticoli(ordine)
        #expect(comparatore.criterio == .scadenza)
        #expect(comparatore.order == .reverse)
        #expect(comparatore.ordine == ordine)

        // Cliccando di nuovo l'intestazione la tabella inverte il verso.
        var invertito = comparatore
        invertito.order = .forward
        #expect(invertito.ordine == OrdineArticoli.articoli)
    }

    @Test func ilComparatoreOrdinaComeLElenco() throws {
        let dispensa = Dispensa(nome: "Casa")
        context.insert(dispensa)
        let nomi = ["Pane", "Burro", "Latte"]
        let articoli = nomi.map { nome in
            let prodotto = Prodotto(nome: nome)
            context.insert(prodotto)
            prodotto.dispensa = dispensa
            let articolo = Articolo()
            context.insert(articolo)
            articolo.prodotto = prodotto
            return articolo
        }
        var ordine = OrdineArticoli(.nome)
        ordine.crescente = false
        let comparatore = ComparatoreArticoli(ordine)
        #expect(articoli.sorted(using: comparatore).map(\.nomeVisualizzato) == ["Pane", "Latte", "Burro"])
        #expect(ordine.ordina(articoli).map(\.nomeVisualizzato) == ["Pane", "Latte", "Burro"])
        #expect(comparatore.compare(articoli[0], articoli[0]) == .orderedSame)
    }

    // MARK: - Colonne

    @Test func leColonneSiSalvanoESiRileggono() {
        var colonne = TableColumnCustomization<Articolo>()
        #expect(ColonnaArticoli.marca.visibile(in: colonne))
        #expect(!ColonnaArticoli.codice.visibile(in: colonne))

        colonne[visibility: ColonnaArticoli.marca.rawValue] = .hidden
        colonne[visibility: ColonnaArticoli.codice.rawValue] = .visible
        let letto: TableColumnCustomization<Articolo> = ArchivioColonne.leggi(ArchivioColonne.scrivi(colonne))
        #expect(letto == colonne)
        #expect(!ColonnaArticoli.marca.visibile(in: letto))
        #expect(ColonnaArticoli.codice.visibile(in: letto))
    }

    @Test func ilNomeRestaSempreVisibile() {
        var colonne = TableColumnCustomization<Articolo>()
        colonne[visibility: ColonnaArticoli.nome.rawValue] = .hidden
        #expect(ColonnaArticoli.nome.visibile(in: colonne))
    }

    @Test func datiMancantiORovinatiDannoLeColonneIniziali() {
        let vuoto: TableColumnCustomization<Articolo> = ArchivioColonne.leggi(Data())
        let rovinato: TableColumnCustomization<Articolo> = ArchivioColonne.leggi(Data("non è json".utf8))
        #expect(vuoto == TableColumnCustomization())
        #expect(rovinato == TableColumnCustomization())
    }

    @Test func laStrutturaNonHaLaColonnaStruttura() {
        #expect(!ColonnaArticoli.disponibili(per: .struttura).contains(.struttura))
        #expect(ColonnaArticoli.disponibili(per: .articoli).contains(.struttura))
    }
}
