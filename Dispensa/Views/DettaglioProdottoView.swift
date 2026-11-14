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
            Section {
                LabeledContent("Categoria") {
                    Text(prodotto.categoria?.percorsoTestuale ?? String(localized: "Senza categoria"))
                }
                LabeledContent("Marca") {
                    Text(prodotto.marca ?? String(localized: "Non indicata"))
                }
                LabeledContent("Codice") {
                    Text(prodotto.codiceBarre ?? String(localized: "Non indicato"))
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
        }
        .formStyle(.grouped)
        .navigationTitle(prodotto.nome)
        .azioniArticolo($azione, daEliminare: $daEliminare)
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
