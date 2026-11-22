//
//  ElencoArticoliView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Articoli presenti in tutte le strutture di una dispensa, ordinati per scadenza, con ricerca per nome.
struct ElencoArticoliView: View {
    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var filtro = FiltroArticoli()
    @State private var mostraNuovoArticolo = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?

    private var presenti: [Articolo] {
        (dispensa.strutture ?? []).flatMap(\.articoliAttivi)
    }

    private var articoli: [Articolo] {
        // Regole di ricerca e filtri in Services/RicercaProdotti.swift e FiltriArticoli.swift.
        Articolo.ordinatiPerScadenza(filtro.applica(presenti).filter { $0.corrisponde(a: ricerca) })
    }

    private var senzaStrutture: Bool {
        dispensa.strutture?.isEmpty ?? true
    }

    var body: some View {
        let articoli = self.articoli
        List {
            if !filtro.vuoto, !articoli.isEmpty {
                RigaFiltriAttivi(filtro: $filtro)
            }
            ForEach(articoli) { articolo in
                RigaArticoloConAzioni(articolo: articolo, mostraStruttura: true, azione: $azione, daEliminare: $daEliminare)
            }
        }
        .navigationTitle("Articoli")
        .filtriArticoli($filtro, dispensa: dispensa, perStorico: false)
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria, #etichetta, struttura o codice"))
        .overlay { statoVuoto }
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuovo articolo", systemImage: "plus") { mostraNuovoArticolo = true }
                    .disabled(senzaStrutture)
            }
        }
        .sheet(isPresented: $mostraNuovoArticolo) {
            // La struttura si sceglie nel modulo.
            ArticoloFormView(dispensa: dispensa, struttura: nil)
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
            if filtro.vuoto || !ricerca.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView.search(text: ricerca)
            } else {
                NessunRisultatoConFiltri(filtro: $filtro)
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
