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
    @State private var nuovoArticolo: RichiestaNuovoArticolo?
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?
    @State private var ricerca = ""
    @State private var stato: StatoArticoli

    /// Gli articoli presenti che passano ricerca e filtri, nell'ordine scelto.

    init(struttura: Struttura) {
        self.struttura = struttura
        // L'elenco si apre con la vista predefinita, se c'è.
        _stato = State(initialValue: StatoArticoli.struttura.conPredefinita(in: struttura.dispensa))
    }
    private var articoli: [Articolo] {
        // Regole in Services/RicercaProdotti.swift, FiltriArticoli.swift e OrdinamentoElenchi.swift.
        stato.ordine.ordina(stato.filtro.applica(struttura.articoliAttivi).filter { $0.corrisponde(a: ricerca) })
    }

    var body: some View {
        let articoli = self.articoli
        let totale = struttura.articoliAttivi.count
        Form {
            if let immagine = struttura.immagine {
                Section {
                    ImmagineSchedaView(dati: immagine)
                }
            }

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
                if stato.mostraRiga {
                    RigaFiltriAttivi(stato: $stato, dispensa: struttura.dispensa)
                }
                if stato.raggruppa {
                    ForEach(RaggruppamentoArticoli.raggruppa(articoli)) { gruppo in
                        RigaGruppoConAzioni(gruppo: gruppo, azione: $azione, daEliminare: $daEliminare)
                    }
                } else {
                    ForEach(articoli) { articolo in
                        RigaArticoloConAzioni(articolo: articolo, azione: $azione, daEliminare: $daEliminare)
                    }
                }
                if articoli.isEmpty, totale > 0 {
                    Text("Nessun articolo corrisponde alla ricerca o ai filtri.")
                        .foregroundStyle(.secondary)
                }
                Button("Aggiungi articolo", systemImage: "plus.circle") {
                    nuovoArticolo = RichiestaNuovoArticolo()
                }
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
        .menuVista($stato, dispensa: struttura.dispensa) {
            if let dispensa = struttura.dispensa {
                FiltriArticoliView(dispensa: dispensa, contesto: .struttura, filtro: $stato.filtro)
            }
        }
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .toolbar {
            ToolbarItem {
                Button("Modifica") { mostraModifica = true }
            }
            ToolbarItem(placement: .primaryAction) {
                PulsanteNuovoArticolo(richiesta: $nuovoArticolo)
            }
        }
        .sheet(item: $nuovoArticolo) { richiesta in
            if let dispensa = struttura.dispensa {
                ArticoloFormView(dispensa: dispensa, struttura: struttura, scansiona: richiesta.scansiona)
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
