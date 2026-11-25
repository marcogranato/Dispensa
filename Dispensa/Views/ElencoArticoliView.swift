//
//  ElencoArticoliView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Articoli presenti in tutte le strutture di una dispensa, con ricerca, filtri e ordinamento.
struct ElencoArticoliView: View {
    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var stato: StatoArticoli
    @State private var nuovoArticolo: RichiestaNuovoArticolo?
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?


    init(dispensa: Dispensa) {
        self.dispensa = dispensa
        // L'elenco si apre con la vista predefinita, se c'è.
        _stato = State(initialValue: StatoArticoli.articoli.conPredefinita(in: dispensa))
    }
    private var presenti: [Articolo] {
        (dispensa.strutture ?? []).flatMap(\.articoliAttivi)
    }

    private var articoli: [Articolo] {
        // Regole in Services/RicercaProdotti.swift, FiltriArticoli.swift e OrdinamentoElenchi.swift.
        stato.ordine.ordina(stato.filtro.applica(presenti).filter { $0.corrisponde(a: ricerca) })
    }

    private var senzaStrutture: Bool {
        dispensa.strutture?.isEmpty ?? true
    }

    var body: some View {
        let articoli = self.articoli
        List {
            if stato.mostraRiga, !articoli.isEmpty {
                RigaFiltriAttivi(stato: $stato, dispensa: dispensa)
            }
            ForEach(articoli) { articolo in
                RigaArticoloConAzioni(articolo: articolo, mostraStruttura: true, azione: $azione, daEliminare: $daEliminare)
            }
        }
        .navigationTitle("Articoli")
        .menuVista($stato, dispensa: dispensa) {
            FiltriArticoliView(dispensa: dispensa, contesto: .articoli, filtro: $stato.filtro)
        }
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria, #etichetta, struttura o codice"))
        .overlay { statoVuoto }
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                PulsanteNuovoArticolo(richiesta: $nuovoArticolo)
                    .disabled(senzaStrutture)
            }
        }
        .sheet(item: $nuovoArticolo) { richiesta in
            // La struttura si sceglie nel modulo.
            ArticoloFormView(dispensa: dispensa, struttura: nil, scansiona: richiesta.scansiona)
        }
    }

    @ViewBuilder
    private var statoVuoto: some View {
        if senzaStrutture {
            ContentUnavailableView(
                "Nessuna struttura",
                systemImage: "square.stack.3d.up",
                description: Text("Crea una struttura nella scheda Strutture, poi aggiungi gli articoli.")
            )
        } else if presenti.isEmpty {
            ContentUnavailableView(
                "Nessun articolo",
                systemImage: "list.bullet",
                description: Text("Gli articoli di tutte le strutture compariranno qui.")
            )
        } else if articoli.isEmpty {
            if stato.filtro.vuoto || !ricerca.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView.search(text: ricerca)
            } else {
                NessunRisultatoConFiltri(stato: $stato, dispensa: dispensa)
            }
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        ElencoArticoliView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
