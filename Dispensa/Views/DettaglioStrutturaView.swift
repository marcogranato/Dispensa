//
//  DettaglioStrutturaView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Caratteristiche di una struttura e articoli presenti (all'inizio per scadenza, l'ordine si può cambiare).
struct DettaglioStrutturaView: View {
    let struttura: Struttura

    @State private var mostraModifica = false
    @State private var mostraNuovoArticolo = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?
    @State private var ordine = OrdineArticoli.articoli

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
                ForEach(ordine.ordina(struttura.articoliAttivi)) { articolo in
                    RigaArticoloConAzioni(articolo: articolo, azione: $azione, daEliminare: $daEliminare)
                }
                Button("Aggiungi articolo", systemImage: "plus.circle") { mostraNuovoArticolo = true }
            } header: {
                Text("Articoli presenti: \(struttura.articoliAttivi.count)")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(struttura.nome)
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .toolbar {
            ToolbarItem {
                Button("Modifica") { mostraModifica = true }
            }
            ToolbarItem {
                MenuOrdinamento(criteri: CriterioArticoli.perStruttura, ordine: $ordine)
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

#Preview {
    let struttura = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Struttura>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        DettaglioStrutturaView(struttura: struttura)
    }
    .modelContainer(.anteprima)
}
