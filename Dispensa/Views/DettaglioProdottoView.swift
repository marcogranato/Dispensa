//
//  DettaglioProdottoView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Scheda di un prodotto in sola lettura: dati, articoli presenti (con la loro struttura) e storico.
/// Si modifica con il pulsante "Modifica".
struct DettaglioProdottoView: View {
    @Environment(\.dismiss) private var dismiss

    let prodotto: Prodotto

    @State private var mostraModifica = false
    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?
    @State private var prodottoDaEliminare: Prodotto?

    /// Vero quando il prodotto è stato eliminato.
    private var eliminato: Bool {
        prodotto.isDeleted || prodotto.modelContext == nil
    }

    private var presenti: [Articolo] {
        Articolo.ordinatiPerScadenza((prodotto.articoli ?? []).filter { $0.stato == .attivo })
    }

    private var nelloStorico: Int {
        (prodotto.articoli ?? []).filter { $0.stato != .attivo }.count
    }

    var body: some View {
        Group {
            if eliminato {
                ContentUnavailableView("Prodotto eliminato", systemImage: "carrot")
            } else {
                contenuto
            }
        }
        .onChange(of: eliminato) {
            if eliminato { dismiss() }
        }
    }

    private var contenuto: some View {
        Form {
            if let immagine = prodotto.immagine {
                Section {
                    ImmagineSchedaView(dati: immagine)
                }
            }

            Section {
                LabeledContent("Categoria") {
                    Text(prodotto.categoria?.percorsoTestuale ?? String(localized: "Senza categoria"))
                }
                LabeledContent("Marca") {
                    Text(prodotto.marca ?? String(localized: "Non indicata"))
                }
                let codici = prodotto.codiciOrdinati
                LabeledContent(codici.count > 1 ? "Codici" : "Codice") {
                    if codici.isEmpty {
                        Text("Non indicato")
                    } else {
                        // Un solo testo, un codice per riga: così VoiceOver li legge tutti.
                        Text(codici.joined(separator: "\n"))
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }
                }
                LabeledContent("Confezione") {
                    Text(Formattazione.confezioneEstesa(
                        parti: prodotto.partiPerConfezione,
                        quantitaPerParte: prodotto.quantitaPerParte,
                        unita: prodotto.unita,
                        tipoParte: prodotto.tipoParte
                    ) ?? String(localized: "Non indicata"))
                }
            }

            let etichette = prodotto.etichetteOrdinate
            if !etichette.isEmpty {
                Section("Etichette") {
                    GettoniEtichetteView(etichette: etichette)
                        .padding(.vertical, 2)
                }
            }

            if let descrizione = prodotto.descrizione {
                Section("Descrizione") {
                    Text(descrizione)
                }
            }
            if let note = prodotto.note {
                Section("Note personali") {
                    Text(note)
                }
            }

            Section {
                ForEach(presenti) { articolo in
                    RigaArticoloConAzioni(articolo: articolo, mostraStruttura: true, azione: $azione, daEliminare: $daEliminare)
                }
            } header: {
                Text("Articoli presenti: \(presenti.count)")
            } footer: {
                if nelloStorico > 0 {
                    Text("Articoli nello storico: \(nelloStorico)")
                }
            }

            Section {
                Button("Elimina prodotto", systemImage: "trash", role: .destructive) { prodottoDaEliminare = prodotto }
                    .tint(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(prodotto.nome)
        .azioniArticolo($azione, daEliminare: $daEliminare)
        .eliminazioneProdotto($prodottoDaEliminare)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifica") { mostraModifica = true }
            }
        }
        .sheet(isPresented: $mostraModifica) {
            if let dispensa = prodotto.dispensa {
                ProdottoFormView(dispensa: dispensa, prodotto: prodotto)
            }
        }
    }
}

#Preview {
    let prodotto = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Prodotto>()).first!
    PilaDiNavigazione {
        DettaglioProdottoView(prodotto: prodotto)
    }
    .modelContainer(.anteprima)
}
