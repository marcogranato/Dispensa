//
//  GestioneEtichetteTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneEtichetteTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
    }

    private func creaProdotto(_ nome: String) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        return prodotto
    }

    @Test func ilNomeSiSalvaSenzaCancellettoNeSpazi() throws {
        let etichetta = try context.creaEtichetta(nome: " #Senza glutine ", colore: .verde, in: dispensa)

        #expect(etichetta.nome == "Senzaglutine")
        #expect(etichetta.nomeConCancelletto == "#Senzaglutine")
        #expect(etichetta.colore == .verde)
        #expect(etichetta.coloreRaw == "verde")
        #expect(dispensa.etichette?.count == 1)
    }

    @Test func nomeVuotoODuplicatoNonAccettato() throws {
        try context.creaEtichetta(nome: "colazione", in: dispensa)

        #expect(throws: ErroreGestioneEtichette.nomeVuoto) {
            try context.creaEtichetta(nome: " # ", in: dispensa)
        }
        #expect(throws: ErroreGestioneEtichette.nomeDuplicato) {
            try context.creaEtichetta(nome: "#Colazióne", in: dispensa)
        }
        #expect(dispensa.etichette?.count == 1)
    }

    @Test func modificaNomeEColore() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", colore: .rosso, in: dispensa)
        let bio = try context.creaEtichetta(nome: "bio", in: dispensa)

        // Può cambiare solo le maiuscole del proprio nome, ma non prendere quello di un'altra.
        try context.modificaEtichetta(colazione, nome: "Colazione", colore: nil)
        #expect(colazione.nome == "Colazione")
        #expect(colazione.colore == nil)
        #expect(throws: ErroreGestioneEtichette.nomeDuplicato) {
            try context.modificaEtichetta(bio, nome: "COLAZIONE", colore: nil)
        }
        #expect(bio.nome == "bio")
    }

    @Test func eliminandolaIProdottiRestanoSenzaEtichetta() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", in: dispensa)
        let bio = try context.creaEtichetta(nome: "bio", in: dispensa)
        let biscotti = creaProdotto("Biscotti")
        biscotti.etichette = [colazione, bio]
        try context.save()

        context.eliminaEtichetta(colazione)
        try context.save()

        #expect(biscotti.etichetteOrdinate.map(\.nome) == ["bio"])
        #expect(dispensa.etichetteOrdinate.map(\.nome) == ["bio"])
        #expect(dispensa.prodotti?.count == 1)
    }

    @Test func etichetteEProdottiInOrdine() throws {
        let colazione = try context.creaEtichetta(nome: "colazione", in: dispensa)
        try context.creaEtichetta(nome: "Bio", in: dispensa)
        let latte = creaProdotto("Latte")
        let biscotti = creaProdotto("Biscotti")
        latte.etichette = [colazione]
        biscotti.etichette = [colazione]

        #expect(dispensa.etichetteOrdinate.map(\.nome) == ["Bio", "colazione"])
        #expect(colazione.prodottiOrdinati.map(\.nome) == ["Biscotti", "Latte"])
    }
}
