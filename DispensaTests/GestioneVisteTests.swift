//
//  GestioneVisteTests.swift
//  DispensaTests
//

import Foundation
import SwiftData
import Testing
@testable import Dispensa

@MainActor
struct GestioneVisteTests {
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

    @Test func salvaERileggeFiltroEOrdine() throws {
        var stato = StatoArticoli.articoli
        stato.filtro.strutture = [frigo.id]
        stato.filtro.tipiStruttura = [.frigorifero]
        stato.filtro.scadenze = [.scaduto, .inScadenza]
        stato.filtro.scadenza.dal = Date(timeIntervalSince1970: 1_000_000)
        stato.ordine.criterio = .nome
        stato.ordine.crescente = false

        let vista = try context.creaVista(nome: "  Frigo in scadenza ", stato: stato, in: dispensa)
        #expect(vista.nome == "Frigo in scadenza")
        #expect(vista.tipo == .articoli)

        var altro = StatoArticoli.articoli
        altro.applica(vista, in: dispensa)
        #expect(altro.filtro == stato.filtro)
        #expect(altro.ordine == stato.ordine)
        #expect(altro.vista == vista.id)
        #expect(altro.vistaApplicata(in: dispensa) === vista)
        #expect(!altro.differisce(da: vista, in: dispensa))
    }

    @Test func modificataEAggiornata() throws {
        var stato = StatoProdotti.prodotti
        stato.filtro.presenze = [.senzaArticoli]
        let vista = try context.creaVista(nome: "Da ricomprare", stato: stato, in: dispensa)
        stato.vista = vista.id

        stato.ordine.criterio = .creazione
        #expect(stato.differisce(da: vista, in: dispensa))

        context.aggiornaVista(vista, con: stato)
        #expect(!stato.differisce(da: vista, in: dispensa))
        #expect(vista.ordine(criteri: CriterioProdotti.allCases, iniziale: .prodotti).criterio == .creazione)
    }

    @Test func azzeraTornaAllOrdineInizialeSoloSeCEraUnaVista() throws {
        var stato = StatoArticoli.storico
        stato.ordine.criterio = .nome
        stato.filtro.esiti = [.buttato]
        stato.azzera()
        #expect(stato.filtro.vuoto)
        #expect(stato.ordine.criterio == .nome)

        let vista = try context.creaVista(nome: "Buttati", stato: stato, in: dispensa)
        stato.applica(vista, in: dispensa)
        #expect(stato.mostraRiga)
        stato.azzera()
        #expect(stato.vista == nil)
        #expect(stato.ordine == OrdineArticoli.storico)
        #expect(!stato.mostraRiga)
    }

    @Test func nomeObbligatorioEUnicoPerElenco() throws {
        let stato = StatoArticoli.articoli
        try context.creaVista(nome: "Scaduti", stato: stato, in: dispensa)

        #expect(throws: ErroreGestioneViste.nomeVuoto) {
            try context.creaVista(nome: "   ", stato: stato, in: dispensa)
        }
        #expect(throws: ErroreGestioneViste.nomeDuplicato) {
            try context.creaVista(nome: "scadutì", stato: stato, in: dispensa)
        }
        // Lo stesso nome va bene in un altro elenco.
        try context.creaVista(nome: "Scaduti", stato: StatoArticoli.storico, in: dispensa)
        #expect(dispensa.viste(per: .articoli).count == 1)
        #expect(dispensa.viste(per: .storico).count == 1)
    }

    @Test func rinominaEdElimina() throws {
        let stato = StatoArticoli.articoli
        let prima = try context.creaVista(nome: "Prima", stato: stato, in: dispensa)
        let seconda = try context.creaVista(nome: "Seconda", stato: stato, in: dispensa)

        try context.rinominaVista(prima, nome: "Prima")
        try context.rinominaVista(prima, nome: "Alfa")
        #expect(prima.nome == "Alfa")
        #expect(throws: ErroreGestioneViste.nomeDuplicato) {
            try context.rinominaVista(prima, nome: "SECONDA")
        }

        context.eliminaVista(seconda)
        #expect(dispensa.viste(per: .articoli).map(\.nome) == ["Alfa"])
    }

    @Test func iCriteriNonValidiPerLElencoTornanoAllIniziale() throws {
        var stato = StatoArticoli.articoli
        stato.ordine.criterio = .struttura
        let vista = try context.creaVista(nome: "Per struttura", stato: stato, in: dispensa)
        // Nella scheda della struttura non si ordina per struttura.
        #expect(vista.ordine(criteri: CriterioArticoli.perStruttura, iniziale: .articoli) == OrdineArticoli.articoli)
    }

    @Test func gliElementiEliminatiVengonoIgnorati() throws {
        let etichetta = try context.creaEtichetta(nome: "bio", in: dispensa)
        let altra = try context.creaEtichetta(nome: "colazione", in: dispensa)
        var stato = StatoProdotti.prodotti
        stato.filtro.etichette = [etichetta.id, altra.id]
        let vista = try context.creaVista(nome: "Bio", stato: stato, in: dispensa)

        context.eliminaEtichetta(etichetta)
        var letto = StatoProdotti.prodotti
        letto.applica(vista, in: dispensa)
        #expect(letto.filtro.etichette == [altra.id])
    }

    @Test func letturaTollerante() throws {
        // Campi mancanti, sconosciuti o non validi tornano al valore iniziale senza perdere gli altri.
        let json = Data(#"{"scadenze":["scaduto"],"esiti":["sconosciuto"],"campoFuturo":1}"#.utf8)
        let filtro = try JSONDecoder().decode(FiltroArticoli.self, from: json)
        #expect(filtro.scadenze == [.scaduto])
        #expect(filtro.esiti.isEmpty)
        #expect(filtro.numeroAttivi == 1)

        let vista = VistaSalvata(nome: "Rovinata", tipo: .articoli)
        context.insert(vista)
        vista.filtroJSON = Data("non è json".utf8)
        #expect(vista.filtro(FiltroArticoli.self) == FiltroArticoli())
    }

    @Test func eliminandoLaDispensaSiEliminanoLeViste() throws {
        try context.creaVista(nome: "Tutto", stato: StatoArticoli.articoli, in: dispensa)
        try context.save()
        context.delete(dispensa)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<VistaSalvata>()) == 0)
    }
}
