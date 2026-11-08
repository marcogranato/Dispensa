//
//  DettaglioStrutturaView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Caratteristiche di una struttura e articoli presenti, ordinati per scadenza.
struct DettaglioStrutturaView: View {
    @Environment(\.modelContext) private var modelContext

    let struttura: Struttura

    @State private var mostraModifica = false
    @State private var mostraNuovoArticolo = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?

    var body: some View {
        Form {
            Section {
                LabeledContent("Tipo") {
                    HStack {
                        Image(systemName: struttura.tipo.simbolo)
                        Text(struttura.nomeTipo)
                    }
                }
                LabeledContent("Ubicazione") {
                    if let ubicazione = struttura.ubicazione {
                        Text(ubicazione.nome)
                    } else {
                        Text("Nessuna")
                    }
                }
                if let numeroRipiani = struttura.numeroRipiani {
                    LabeledContent("Ripiani") { Text(numeroRipiani, format: .number) }
                }
                if let numeroCassetti = struttura.numeroCassetti {
                    LabeledContent("Cassetti") { Text(numeroCassetti, format: .number) }
                }
            }

            if let note = struttura.note {
                Section("Note") {
                    Text(note)
                }
            }

            Section {
                ForEach(Articolo.ordinatiPerScadenza(struttura.articoliAttivi)) { articolo in
                    rigaArticolo(articolo)
                }
                Button("Aggiungi articolo", systemImage: "plus.circle") { mostraNuovoArticolo = true }
            } header: {
                Text("Articoli presenti: \(struttura.articoliAttivi.count)")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(struttura.nome)
        .navigationDestination(for: Articolo.self) { articolo in
            DettaglioArticoloView(articolo: articolo)
        }
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .toolbar {
            ToolbarItem {
                Button("Modifica") { mostraModifica = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Nuovo articolo", systemImage: "plus") { mostraNuovoArticolo = true }
            }
        }
        .sheet(isPresented: $mostraNuovoArticolo) {
            if let dispensa = struttura.dispensa {
                ArticoloFormView(dispensa: dispensa, struttura: struttura)
            }
        }
        .sheet(isPresented: $mostraModifica) {
            if let dispensa = struttura.dispensa {
                StrutturaFormView(dispensa: dispensa, struttura: struttura)
            }
        }
    }
}

extension DettaglioStrutturaView {
    /// Scorrendo verso destra si preleva una parte; verso sinistra si butta.
    private func rigaArticolo(_ articolo: Articolo) -> some View {
        NavigationLink(value: articolo) {
            RigaArticoloView(articolo: articolo)
        }
        .swipeActions(edge: .leading) {
            Button("Preleva 1", systemImage: "minus.circle") {
                // Una parte si può sempre prelevare da un articolo presente: l'errore non può verificarsi.
                try? modelContext.preleva(articolo)
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button("Butta", systemImage: "trash.slash") { azione = AzioneArticolo(tipo: .butta, articolo: articolo) }
                .tint(.orange)
        }
        .contextMenu {
            MenuAzioniArticolo(articolo: articolo, azione: $azione, daEliminare: $daEliminare)
        }
    }
}

#Preview {
    let struttura = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Struttura>(sortBy: [SortDescriptor(\.nome)])).first!
    NavigationStack {
        DettaglioStrutturaView(struttura: struttura)
    }
    .modelContainer(.anteprima)
}
