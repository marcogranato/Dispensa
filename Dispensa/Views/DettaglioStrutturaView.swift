//
//  DettaglioStrutturaView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Caratteristiche di una struttura e articoli presenti, con ricerca, filtri e ordinamento (all'inizio per scadenza).
struct DettaglioStrutturaView: View {
    let struttura: Struttura

    @State private var mostraModifica = false
    @State private var mostraNuovoArticolo = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?
    @State private var ricerca = ""
    @State private var filtro = FiltroArticoli()
    @State private var ordine = OrdineArticoli.articoli

    /// Gli articoli presenti che passano ricerca e filtri, nell'ordine scelto.
    private var articoli: [Articolo] {
        // Regole in Services/RicercaProdotti.swift, FiltriArticoli.swift e OrdinamentoElenchi.swift.
        ordine.ordina(filtro.applica(struttura.articoliAttivi).filter { $0.corrisponde(a: ricerca) })
    }

    var body: some View {
        let articoli = self.articoli
        let totale = struttura.articoliAttivi.count
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
                if !filtro.vuoto {
                    RigaFiltriAttivi(filtro: $filtro)
                }
                ForEach(articoli) { articolo in
                    RigaArticoloConAzioni(articolo: articolo, azione: $azione, daEliminare: $daEliminare)
                }
                if articoli.isEmpty, totale > 0 {
                    Text("Nessun articolo corrisponde alla ricerca o ai filtri.")
                        .foregroundStyle(.secondary)
                }
                Button("Aggiungi articolo", systemImage: "plus.circle") { mostraNuovoArticolo = true }
            } header: {
                if articoli.count == totale {
                    Text("Articoli presenti: \(totale)")
                } else {
                    Text("Articoli presenti: \(articoli.count) di \(totale)")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(struttura.nome)
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria, #etichetta o codice"))
        .filtriArticoli($filtro, dispensa: struttura.dispensa, contesto: .struttura)
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
