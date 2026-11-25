//
//  GestioneCodiciTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneCodiciTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
    }

    private func creaProdotto(_ nome: String, marca: String? = nil, in dispensa: Dispensa? = nil) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa ?? self.dispensa
        prodotto.marca = marca
        return prodotto
    }

    @Test func codiciPulitiSenzaVuotiNeDoppioni() throws {
        #expect(Codici.puliti([" 123 ", "", "456", "123", "  "]) == ["123", "456"])

        let latte = creaProdotto("Latte")
        try context.impostaCodici(["111", " 222 ", "111"], a: latte)
        #expect(latte.codiciOrdinati == ["111", "222"])
    }

    @Test func sostituireICodiciTieneQuelliRimasti() throws {
        let latte = creaProdotto("Latte")
        try context.impostaCodici(["111", "222"], a: latte)
        let primo = try #require(latte.codici?.first { $0.codice == "111" })

        try context.impostaCodici(["111", "333"], a: latte)
        #expect(latte.codiciOrdinati == ["111", "333"])
        // Il codice rimasto è lo stesso oggetto, non uno nuovo.
        #expect(latte.codici?.contains { $0 === primo } == true)

        try context.impostaCodici([], a: latte)
        #expect(latte.codiciOrdinati.isEmpty)
    }

    @Test func unCodiceAppartieneAUnSoloProdotto() throws {
        let latte = creaProdotto("Latte", marca: "Granarolo")
        let panna = creaProdotto("Panna")
        try context.impostaCodici(["8001"], a: latte)

        #expect(throws: ErroreGestioneCodici.codiceGiaUsato(codice: "8001", prodotto: "Latte · Granarolo")) {
            try context.impostaCodici(["9000", "8001"], a: panna)
        }
        // Niente salvato a metà.
        #expect(panna.codiciOrdinati.isEmpty)
        #expect(dispensa.codiceGiaUsato(tra: ["8001"], escluso: latte) == nil)

        // In un'altra dispensa lo stesso codice va bene.
        let altra = Dispensa(nome: "Mare")
        context.insert(altra)
        let latteAlMare = creaProdotto("Latte", in: altra)
        try context.impostaCodici(["8001"], a: latteAlMare)
        #expect(altra.prodotto(conCodice: "8001") === latteAlMare)
        #expect(dispensa.prodotto(conCodice: " 8001 ") === latte)
    }

    @Test func laRicercaTrovaQualsiasiCodice() throws {
        let latte = creaProdotto("Latte")
        try context.impostaCodici(["111", "222"], a: latte)
        #expect(latte.corrisponde(a: "222"))
        #expect(latte.corrisponde(a: "111"))
        #expect(!latte.corrisponde(a: "22"))
        #expect(dispensa.prodotto(conCodice: "222") === latte)
        #expect(dispensa.prodotto(conCodice: "") == nil)
    }

    @Test func ilVecchioCodiceSiSpostaUnaSolaVolta() throws {
        let latte = creaProdotto("Latte")
        latte.codiceBarre = " 8001 "
        let pane = creaProdotto("Pane")
        pane.codiceBarre = ""

        context.spostaCodiciVecchi()
        #expect(latte.codiciOrdinati == ["8001"])
        #expect(latte.codiceBarre == nil)
        #expect(pane.codiciOrdinati.isEmpty)
        #expect(pane.codiceBarre == nil)

        context.spostaCodiciVecchi()
        #expect(latte.codiciOrdinati == ["8001"])
        #expect(try context.fetchCount(FetchDescriptor<CodiceBarre>()) == 1)
    }

    @Test func eliminandoIlProdottoSiEliminanoICodici() throws {
        let latte = creaProdotto("Latte")
        try context.impostaCodici(["111", "222"], a: latte)
        try context.save()
        context.delete(latte)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<CodiceBarre>()) == 0)
    }
}

extension GestioneCodiciTests {
    @Test func doveVaIlCodiceLetto() {
        #expect(Codici.posizione(del: "8001", in: [""]) == .campoVuoto(0))
        #expect(Codici.posizione(del: "8001", in: ["7000", " ", ""]) == .campoVuoto(1))
        #expect(Codici.posizione(del: "8001", in: ["7000"]) == .inFondo)
        #expect(Codici.posizione(del: "8001", in: []) == .inFondo)
        #expect(Codici.posizione(del: " 8001\n", in: ["7000", " 8001 ", ""]) == .giaPresente(1))
    }
}

extension GestioneCodiciTests {
    @Test func unCodiceLettoSiCollegaSoloSeLibero() {
        let latte = creaProdotto("Latte")
        let panna = creaProdotto("Panna")

        #expect(context.aggiungiCodice(" 8001 ", a: latte))
        #expect(latte.codiciOrdinati == ["8001"])
        // Già suo: niente doppioni.
        #expect(!context.aggiungiCodice("8001", a: latte))
        #expect(latte.codiciOrdinati == ["8001"])
        // Di un altro prodotto: non si sposta.
        #expect(!context.aggiungiCodice("8001", a: panna))
        #expect(panna.codiciOrdinati.isEmpty)
        #expect(latte.codiciOrdinati == ["8001"])
        // Vuoto: ignorato.
        #expect(!context.aggiungiCodice("  ", a: panna))
        #expect(dispensa.prodotto(conCodice: "8001") === latte)
    }
}
