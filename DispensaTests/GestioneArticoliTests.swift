//
//  GestioneArticoliTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneArticoliTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    let dispensa: Dispensa
    let cantina: Struttura
    let frigo: Struttura
    let prodotto: Prodotto

    init() throws {
        container = try creaContainerDiTest()
        let context = container.mainContext
        dispensa = Dispensa(nome: "Casa")
        cantina = Struttura(nome: "Cantina", tipo: .scaffale)
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        prodotto = Prodotto(nome: "Acqua")
        context.insert(dispensa)
        for struttura in [cantina, frigo] {
            context.insert(struttura)
            struttura.dispensa = dispensa
        }
        context.insert(prodotto)
        prodotto.dispensa = dispensa
    }

    /// Crea un articolo da `parti` parti nella cantina.
    private func creaArticolo(parti: Int = 6) -> Articolo {
        let articolo = Articolo(partiTotali: parti)
        articolo.quantitaPerParte = 1.5
        articolo.unita = .litri
        articolo.dataScadenza = Date(timeIntervalSince1970: 2_000_000_000)
        context.insert(articolo)
        articolo.prodotto = prodotto
        articolo.dispensa = dispensa
        articolo.struttura = cantina
        return articolo
    }

    private func numeroArticoli() throws -> Int {
        try context.fetchCount(FetchDescriptor<Articolo>())
    }

    // MARK: - Prelievo

    @Test func prelevaRiduceLeParti() throws {
        let articolo = creaArticolo()
        try context.preleva(articolo, parti: 2)
        #expect(articolo.partiRimaste == 4)
        #expect(articolo.stato == .attivo)
    }

    @Test func prelevaFinoAZeroMandaNelloStoricoComeConsumato() throws {
        let articolo = creaArticolo(parti: 2)
        try context.preleva(articolo, parti: 2)
        #expect(articolo.partiRimaste == 0)
        #expect(articolo.stato == .consumato)
        #expect(articolo.dataUscita != nil)
        #expect(cantina.articoliAttivi.isEmpty)
    }

    @Test func prelevaConStoricoDisattivatoEliminaLArticolo() throws {
        dispensa.storicoAbilitato = false
        let articolo = creaArticolo(parti: 1)
        try context.preleva(articolo)
        try context.save()
        #expect(try numeroArticoli() == 0)
    }

    @Test(arguments: [0, -1, 7])
    func prelevaRifiutaPartiNonValide(parti: Int) {
        let articolo = creaArticolo()
        #expect(throws: ErroreGestioneArticoli.partiNonValide) {
            try context.preleva(articolo, parti: parti)
        }
        #expect(articolo.partiRimaste == 6)
    }

    @Test func nonSiPrelevaDaUnArticoloNelloStorico() throws {
        let articolo = creaArticolo(parti: 1)
        try context.preleva(articolo)
        #expect(throws: ErroreGestioneArticoli.articoloNonPresente) {
            try context.preleva(articolo)
        }
    }

    // MARK: - Scarto

    @Test func buttaContaLoSprecoERegistraIlMotivo() throws {
        let articolo = creaArticolo()
        try context.preleva(articolo, parti: 4)
        try context.butta(articolo, parti: 2, motivo: .scaduto)
        #expect(articolo.stato == .buttato)
        #expect(articolo.partiButtate == 2)
        #expect(articolo.motivoScarto == .scaduto)
    }

    @Test func buttaParzialmenteLasciaLArticoloInDispensa() throws {
        let articolo = creaArticolo()
        try context.butta(articolo, parti: 1, motivo: .avariato)
        #expect(articolo.stato == .attivo)
        #expect(articolo.partiRimaste == 5)
        #expect(articolo.partiButtate == 1)
    }

    // MARK: - Spostamento

    @Test func spostaLArticoloIntero() throws {
        let articolo = creaArticolo()
        let spostato = try context.sposta(articolo, in: frigo)
        #expect(spostato === articolo)
        #expect(articolo.struttura === frigo)
        #expect(try numeroArticoli() == 1)
    }

    @Test func spostaAlcunePartiDivideLaConfezione() throws {
        let articolo = creaArticolo()
        try context.preleva(articolo, parti: 1)

        let spostato = try context.sposta(articolo, in: frigo, parti: 2)

        #expect(spostato !== articolo)
        #expect(spostato.struttura === frigo)
        #expect(spostato.partiTotali == 2)
        #expect(spostato.partiRimaste == 2)
        #expect(spostato.prodotto === prodotto)
        #expect(spostato.dispensa === dispensa)
        #expect(spostato.dataScadenza == articolo.dataScadenza)
        #expect(spostato.quantitaPerParte == 1.5)
        #expect(spostato.unita == .litri)

        #expect(articolo.struttura === cantina)
        #expect(articolo.partiTotali == 4)
        #expect(articolo.partiRimaste == 3)
    }

    @Test func nonSiSpostaInUnaStrutturaDiAltraDispensa() throws {
        let altra = Dispensa(nome: "Mare")
        let strutturaAltrove = Struttura(nome: "Frigo mare", tipo: .frigorifero)
        context.insert(altra)
        context.insert(strutturaAltrove)
        strutturaAltrove.dispensa = altra
        let articolo = creaArticolo()

        #expect(throws: ErroreGestioneArticoli.strutturaDiAltraDispensa) {
            try context.sposta(articolo, in: strutturaAltrove)
        }
        #expect(articolo.struttura === cantina)
    }

    // MARK: - Storico

    @Test func rimettiInDispensaAnnullaLUscita() throws {
        let articolo = creaArticolo(parti: 2)
        try context.butta(articolo, parti: 2, motivo: .scaduto)

        try context.rimettiInDispensa(articolo, parti: 2)

        #expect(articolo.stato == .attivo)
        #expect(articolo.partiRimaste == 2)
        #expect(articolo.partiButtate == 0)
        #expect(articolo.motivoScarto == nil)
        #expect(articolo.dataUscita == nil)
    }

    @Test func rimettiInDispensaRichiedeUnaStrutturaSeQuellaOriginaleNonEsistePiu() throws {
        let articolo = creaArticolo(parti: 1)
        try context.preleva(articolo)
        context.eliminaStruttura(cantina)
        try context.save()

        #expect(throws: ErroreGestioneArticoli.strutturaMancante) {
            try context.rimettiInDispensa(articolo)
        }
        try context.rimettiInDispensa(articolo, in: frigo)
        #expect(articolo.struttura === frigo)
    }

    @Test func eliminaDalloStoricoIgnoraGliArticoliPresenti() throws {
        let presente = creaArticolo()
        let uscito = creaArticolo(parti: 1)
        try context.preleva(uscito)

        context.eliminaDalloStorico([presente, uscito])
        try context.save()

        let rimasti = try context.fetch(FetchDescriptor<Articolo>())
        #expect(rimasti.count == 1)
        #expect(rimasti.first === presente)
    }

    @Test func svuotaStoricoEliminaSoloGliArticoliUsciti() throws {
        _ = creaArticolo()
        for _ in 0..<3 {
            try context.preleva(creaArticolo(parti: 1))
        }
        try context.save()

        context.svuotaStorico(di: dispensa)
        try context.save()

        #expect(try numeroArticoli() == 1)
    }

    // MARK: - Prodotti

    @Test func nonSiEliminaUnProdottoConArticoliPresenti() throws {
        _ = creaArticolo()
        #expect(throws: ErroreGestioneArticoli.prodottoConArticoliPresenti) {
            try context.eliminaProdotto(prodotto)
        }
    }

    @Test func eliminareUnProdottoEliminaAncheIlSuoStorico() throws {
        try context.preleva(creaArticolo(parti: 1))
        try context.save()

        try context.eliminaProdotto(prodotto)
        try context.save()

        #expect(try numeroArticoli() == 0)
        #expect(try context.fetchCount(FetchDescriptor<Prodotto>()) == 0)
    }

    // MARK: - Scadenza

    @Test func statoScadenzaConfrontaSoloIGiorni() throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = TimeZone(identifier: "Europe/Rome")!
        let oggi = calendario.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 23))!
        func giorno(_ giorno: Int) -> Date {
            calendario.date(from: DateComponents(year: 2026, month: 11, day: giorno, hour: 1))!
        }

        let articolo = Articolo()
        #expect(articolo.statoScadenza(oggi: oggi, calendario: calendario) == .senzaScadenza)

        articolo.dataScadenza = giorno(7)
        #expect(articolo.statoScadenza(oggi: oggi, calendario: calendario) == .scaduto)
        articolo.dataScadenza = giorno(8)
        #expect(articolo.statoScadenza(oggi: oggi, calendario: calendario) == .inScadenza)
        articolo.dataScadenza = giorno(11)
        #expect(articolo.statoScadenza(oggi: oggi, calendario: calendario) == .inScadenza)
        articolo.dataScadenza = giorno(12)
        #expect(articolo.statoScadenza(oggi: oggi, calendario: calendario) == .valido)
    }
}
