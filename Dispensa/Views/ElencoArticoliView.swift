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
    @State private var mostraNuovoArticolo = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?

    private var presenti: [Articolo] {
        (dispensa.strutture ?? []).flatMap(\.articoliAttivi)
    }

    private var articoli: [Articolo] {
        let testo = ricerca.trimmingCharacters(in: .whitespacesAndNewlines)
        let trovati = testo.isEmpty
            ? presenti
            : presenti.filter { $0.nomeVisualizzato.localizedStandardContains(testo) }
        return Articolo.ordinatiPerScadenza(trovati)
    }

    private var senzaStrutture: Bool {
        dispensa.strutture?.isEmpty ?? true
    }

    var body: some View {
        List {
            ForEach(articoli) { articolo in
                RigaArticoloConAzioni(articolo: articolo, mostraStruttura: true, azione: $azione, daEliminare: $daEliminare)
            }
        }
        .navigationTitle("Articoli")
        .searchable(text: $ricerca, prompt: Text("Cerca per nome"))
        .navigationDestination(for: Articolo.self) { articolo in
            DettaglioArticoloView(articolo: articolo)
        }
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
            ContentUnavailableView.search(text: ricerca)
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    NavigationStack {
        ElencoArticoliView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
