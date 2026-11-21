//
//  EtichetteView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Valore di navigazione per aprire l'elenco delle etichette di una dispensa (vedi `PilaDiNavigazione`).
struct ElencoEtichette: Hashable {
    let dispensa: Dispensa
}

/// Etichette (hashtag) di una dispensa, aperte dalla scheda Prodotti.
/// Il clic su un'etichetta apre la sua scheda; modifica ed eliminazione anche da scorrimento e menu contestuale.
struct EtichetteView: View {
    let dispensa: Dispensa

    @State private var modulo: ModuloEtichetta?
    @State private var etichettaDaEliminare: Etichetta?

    var body: some View {
        List {
            ForEach(dispensa.etichetteOrdinate) { etichetta in
                RigaNavigabile(valore: etichetta) {
                    RigaEtichettaView(etichetta: etichetta)
                }
                .contextMenu {
                    pulsanteModifica(etichetta)
                    pulsanteElimina(etichetta)
                }
                .swipeActions {
                    pulsanteElimina(etichetta)
                    pulsanteModifica(etichetta)
                }
            }
        }
        .navigationTitle("Etichette")
        .overlay {
            if dispensa.etichette?.isEmpty ?? true {
                ContentUnavailableView {
                    Label("Nessuna etichetta", systemImage: "number")
                } description: {
                    Text("Le etichette sono hashtag da dare ai prodotti, per esempio #colazione o #senzaglutine.")
                } actions: {
                    Button("Aggiungi un'etichetta") { modulo = .nuova }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuova etichetta", systemImage: "plus") { modulo = .nuova }
            }
        }
        .moduloEtichetta($modulo, dispensa: dispensa)
        .eliminazioneEtichetta($etichettaDaEliminare)
    }

    private func pulsanteModifica(_ etichetta: Etichetta) -> some View {
        Button("Modifica", systemImage: "pencil") { modulo = .modifica(etichetta) }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ etichetta: Etichetta) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) { etichettaDaEliminare = etichetta }
    }
}

/// Riga di un'etichetta: gettone colorato e numero di prodotti che la usano.
struct RigaEtichettaView: View {
    let etichetta: Etichetta

    var body: some View {
        let prodotti = etichetta.prodotti?.count ?? 0
        HStack {
            GettoneEtichettaView(etichetta)
            Spacer()
            Text(prodotti, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(Text("Prodotti: \(prodotti)"))
        }
    }
}

/// Scheda di un'etichetta in sola lettura: colore e prodotti che la usano.
struct DettaglioEtichettaView: View {
    @Environment(\.dismiss) private var dismiss

    let etichetta: Etichetta

    @State private var modulo: ModuloEtichetta?
    @State private var etichettaDaEliminare: Etichetta?

    private var eliminata: Bool {
        etichetta.isDeleted || etichetta.modelContext == nil
    }

    var body: some View {
        Group {
            if eliminata {
                ContentUnavailableView("Etichetta eliminata", systemImage: "number")
            } else {
                contenuto
            }
        }
        .onChange(of: eliminata) {
            if eliminata { dismiss() }
        }
    }

    private var contenuto: some View {
        let prodotti = etichetta.prodottiOrdinati
        return Form {
            Section {
                LabeledContent("Colore") {
                    if let colore = etichetta.colore {
                        Text(colore.nomeLocalizzato)
                    } else {
                        Text("Nessuno")
                    }
                }
            }

            Section {
                ForEach(prodotti) { prodotto in
                    RigaNavigabile(valore: prodotto) {
                        HStack {
                            IconaProdottoView(icona: prodotto.iconaEffettiva)
                            Text(prodotto.nomeConMarca)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            } header: {
                Text("Prodotti: \(prodotti.count)")
            } footer: {
                if prodotti.isEmpty {
                    Text("Per dare questa etichetta a un prodotto sceglila nel modulo del prodotto.")
                }
            }

            Section {
                Button("Elimina etichetta", systemImage: "trash", role: .destructive) {
                    etichettaDaEliminare = etichetta
                }
                .tint(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(etichetta.nomeConCancelletto)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifica") { modulo = .modifica(etichetta) }
            }
        }
        .moduloEtichetta($modulo, dispensa: etichetta.dispensa)
        .eliminazioneEtichetta($etichettaDaEliminare)
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        EtichetteView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
