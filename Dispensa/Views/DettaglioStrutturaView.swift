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
    @State private var stato: StatoArticoli

    init(struttura: Struttura) {
        self.struttura = struttura
        // L'elenco si apre con la vista predefinita, se c'è.
        _stato = State(initialValue: StatoArticoli.struttura.conPredefinita(in: struttura.dispensa))
    }

    /// Gli articoli presenti che passano ricerca e filtri, nell'ordine scelto.
    private var articoli: [Articolo] {
        // Regole in Services/RicercaProdotti.swift, FiltriArticoli.swift e OrdinamentoElenchi.swift.
        stato.ordine.ordina(stato.filtro.applica(struttura.articoliAttivi).filter { $0.corrisponde(a: ricerca) })
    }

    var body: some View {
        let articoli = self.articoli
        let totale = struttura.articoliAttivi.count
        DisposizioneElenco { tabella in
            Group {
                if tabella {
                    tabellaConCaratteristiche(articoli: articoli, totale: totale)
                } else {
                    modulo(articoli: articoli, totale: totale)
                }
            }
            .menuVista($stato, dispensa: struttura.dispensa) {
                if let dispensa = struttura.dispensa {
                    FiltriArticoliView(dispensa: dispensa, contesto: .struttura, filtro: $stato.filtro)
                }
            } colonne: {
                if tabella {
                    MenuColonne(.struttura, righe: Articolo.self, colonne: ColonnaArticoli.disponibili(per: .struttura))
                }
            }
        }
        .navigationTitle(struttura.nome)
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria, #etichetta o codice"))
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

    /// iPhone e finestre strette: caratteristiche e articoli in un unico modulo.
    private func modulo(articoli: [Articolo], totale: Int) -> some View {
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
                if stato.mostraRiga {
                    RigaFiltriAttivi(stato: $stato, dispensa: struttura.dispensa)
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
    }

    /// iPad e Mac: le caratteristiche in un riquadro e sotto la tabella degli articoli.
    private func tabellaConCaratteristiche(articoli: [Articolo], totale: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                DisposizioneAFlusso(spaziatura: 24) {
                    campo("Tipo") {
                        Label(struttura.nomeTipo, systemImage: struttura.tipo.simbolo)
                    }
                    campo("Ubicazione") {
                        if let ubicazione = struttura.ubicazione {
                            Text(ubicazione.nome)
                        } else {
                            Text("Nessuna")
                        }
                    }
                    if let numeroRipiani = struttura.numeroRipiani {
                        campo("Ripiani") { Text(numeroRipiani, format: .number) }
                    }
                    if let numeroCassetti = struttura.numeroCassetti {
                        campo("Cassetti") { Text(numeroCassetti, format: .number) }
                    }
                    campo("Articoli presenti") {
                        if articoli.count == totale {
                            Text(totale, format: .number)
                        } else {
                            Text("\(articoli.count) di \(totale)")
                        }
                    }
                }
                if let note = struttura.note {
                    Text(note)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding()
            Divider()
            if stato.mostraRiga {
                RigaFiltriAttivi(stato: $stato, dispensa: struttura.dispensa)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                Divider()
            }
            TabellaArticoliView(
                articoli: articoli,
                tipo: .struttura,
                ordine: $stato.ordine,
                azione: $azione,
                daEliminare: $daEliminare
            )
            .overlay {
                if totale == 0 {
                    ContentUnavailableView {
                        Label("Nessun articolo", systemImage: "list.bullet")
                    } description: {
                        Text("Gli articoli di questa struttura compariranno qui.")
                    } actions: {
                        Button("Aggiungi articolo") { mostraNuovoArticolo = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if articoli.isEmpty {
                    ContentUnavailableView(
                        "Nessun risultato",
                        systemImage: "magnifyingglass",
                        description: Text("Nessun articolo corrisponde alla ricerca o ai filtri.")
                    )
                }
            }
        }
    }

    /// Una caratteristica del riquadro: titolo piccolo sopra, valore sotto.
    private func campo<Valore: View>(_ titolo: LocalizedStringKey, @ViewBuilder valore: () -> Valore) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo)
                .font(.caption)
                .foregroundStyle(.secondary)
            valore()
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
