//
//  RaggruppamentoArticoliTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct RaggruppamentoArticoliTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    let dispensa: Dispensa
    let frigo: Struttura
    let scaffale: Struttura
    let calendario = Calendar(identifier: .gregorian)
    /// Un "oggi" fisso: i test non dipendono dal giorno in cui girano.
    let oggi: Date

    init() throws {
        container = try creaContainerDiTest()
        dispensa = Dispensa(nome: "Casa")
        container.mainContext.insert(dispensa)
        frigo = Struttura(nome: "Frigo", tipo: .frigorifero)
        scaffale = Struttura(nome: "Scaffale", tipo: .scaffale)
        container.mainContext.insert(frigo)
        container.mainContext.insert(scaffale)
        frigo.dispensa = dispensa
        scaffale.dispensa = dispensa
        oggi = calendario.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 12))!
    }

    private func giorno(_ differenza: Int) -> Date {
        calendario.date(byAdding: .day, value: differenza, to: oggi)!
    }

    private func prodotto(_ nome: String) -> Prodotto {
        let prodotto = Prodotto(nome: nome)
        context.insert(prodotto)
        prodotto.dispensa = dispensa
        return prodotto
    }

    @discardableResult
    private func articolo(
        _ prodotto: Prodotto?,
        in struttura: Struttura,
        scadenza: Int? = nil,
        inserito: Int = -10,
        parti: Int = 1,
        rimaste: Int? = nil
    ) -> Articolo {
        let articolo = Articolo(partiTotali: parti)
        context.insert(articolo)
        articolo.prodotto = prodotto
        articolo.struttura = struttura
        articolo.dispensa = dispensa
        articolo.partiRimaste = rimaste ?? parti
        articolo.dataInserimento = giorno(inserito)
        articolo.dataScadenza = scadenza.map { giorno($0) }
        return articolo
    }

    @Test func gliArticoliDelloStessoProdottoFormanoUnGruppo() {
        let cereali = prodotto("Gran Cereale")
        let latte = prodotto("Latte")
        let elenco = [
            articolo(cereali, in: frigo),
            articolo(latte, in: frigo),
            articolo(cereali, in: scaffale),
            articolo(cereali, in: scaffale),
        ]

        let gruppi = RaggruppamentoArticoli.raggruppa(elenco)
        // Il gruppo prende il posto della sua prima confezione.
        #expect(gruppi.map { $0.articoli[0].nomeVisualizzato } == ["Gran Cereale", "Latte"])
        #expect(gruppi[0].confezioni == 3)
        #expect(gruppi[0].multiplo)
        #expect(gruppi[0].strutture == ["Frigo", "Scaffale"])
        #expect(!gruppi[1].multiplo)
        #expect(Set(gruppi.map(\.id)).count == 2)
    }

    @Test func gliArticoliSenzaProdottoRestanoSeparati() {
        let elenco = [articolo(nil, in: frigo), articolo(nil, in: frigo)]
        let gruppi = RaggruppamentoArticoli.raggruppa(elenco)
        #expect(gruppi.count == 2)
        #expect(gruppi.allSatisfy { !$0.multiplo })
    }

    @Test func dataPiuVicinaEStatoPeggiore() {
        let yogurt = prodotto("Yogurt")
        let elenco = [
            articolo(yogurt, in: frigo, scadenza: 10),
            articolo(yogurt, in: frigo, scadenza: -1),
            articolo(yogurt, in: frigo),
        ]
        let gruppo = RaggruppamentoArticoli.raggruppa(elenco)[0]
        #expect(gruppo.scadenzaPiuVicina == giorno(-1))
        #expect(gruppo.statoPeggiore(oggi: oggi, calendario: calendario) == .scaduto)

        let senzaDate = RaggruppamentoArticoli.raggruppa([articolo(prodotto("Sale"), in: frigo)])[0]
        #expect(senzaDate.scadenzaPiuVicina == nil)
        #expect(senzaDate.statoPeggiore(oggi: oggi, calendario: calendario) == .senzaScadenza)
    }

    @Test func partiRimasteInTutteLeConfezioni() {
        let biscotti = prodotto("Biscotti")
        let elenco = [
            articolo(biscotti, in: frigo, parti: 6, rimaste: 4),
            articolo(biscotti, in: frigo, parti: 6),
        ]
        let gruppo = RaggruppamentoArticoli.raggruppa(elenco)[0]
        #expect(gruppo.conPiuParti)
        #expect(gruppo.partiRimaste == 10)
    }

    @Test func siPrelevaDallaConfezioneCheScadePrima() throws {
        let latte = prodotto("Latte")
        let lontano = articolo(latte, in: frigo, scadenza: 8)
        let vicino = articolo(latte, in: scaffale, scadenza: 2)
        let senzaData = articolo(latte, in: frigo)
        let gruppo = RaggruppamentoArticoli.raggruppa([lontano, senzaData, vicino])[0]
        #expect(gruppo.daPrelevare === vicino)

        try context.preleva(gruppo.daPrelevare)
        #expect(vicino.stato == .consumato)
        #expect(lontano.partiRimaste == 1)
        #expect(senzaData.partiRimaste == 1)
    }

    @Test func senzaDateSiPrelevaDallaApertaPoiDallaPiuVecchia() {
        let biscotti = prodotto("Biscotti")
        let nuova = articolo(biscotti, in: frigo, inserito: -1, parti: 6)
        let vecchia = articolo(biscotti, in: frigo, inserito: -20, parti: 6)
        #expect(RaggruppamentoArticoli.raggruppa([nuova, vecchia])[0].daPrelevare === vecchia)

        let aperta = articolo(biscotti, in: frigo, inserito: -2, parti: 6, rimaste: 3)
        #expect(RaggruppamentoArticoli.raggruppa([nuova, vecchia, aperta])[0].daPrelevare === aperta)
    }

    @Test func laVistaRicordaIlRaggruppamento() throws {
        var stato = StatoArticoli.articoli
        #expect(stato.puoRaggruppare && stato.raggruppa)
        #expect(StatoArticoli.struttura.puoRaggruppare && StatoArticoli.struttura.raggruppa)
        #expect(!StatoArticoli.storico.puoRaggruppare)

        stato.raggruppa = false
        #expect(!stato.allInizio)
        let vista = try context.creaVista(nome: "Tutte le confezioni", stato: stato, in: dispensa)
        #expect(vista.raggruppa == false)

        var nuovo = StatoArticoli.articoli
        nuovo.applica(vista, in: dispensa)
        #expect(!nuovo.raggruppa)
        #expect(!nuovo.differisce(da: vista, in: dispensa))
        nuovo.raggruppa = true
        #expect(nuovo.differisce(da: vista, in: dispensa))

        // "Mostra tutto" torna come all'apertura dell'elenco.
        nuovo.raggruppa = false
        nuovo.mostraTutto()
        #expect(nuovo.raggruppa)

        // Una vista salvata prima del raggruppamento usa il valore iniziale dell'elenco.
        vista.raggruppa = nil
        var vecchia = StatoArticoli.articoli
        vecchia.raggruppa = false
        vecchia.applica(vista, in: dispensa)
        #expect(vecchia.raggruppa)

        // Lo storico non salva il raggruppamento.
        let storico = try context.creaVista(nome: "Storico", stato: StatoArticoli.storico, in: dispensa)
        #expect(storico.raggruppa == nil)
    }
}
