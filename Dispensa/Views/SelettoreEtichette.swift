//
//  SelettoreEtichette.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Righe di un modulo per scegliere le etichette di un prodotto: i gettoni di quelle scelte
/// e un pulsante che apre l'elenco con le spunte (da cui se ne può anche creare una nuova).
struct SelettoreEtichette: View {
    let dispensa: Dispensa
    /// Gli `id` delle etichette scelte.
    @Binding var selezione: Set<UUID>

    @State private var aperto = false

    private var scelte: [Etichetta] {
        dispensa.etichetteOrdinate.filter { selezione.contains($0.id) }
    }

    var body: some View {
        if !scelte.isEmpty {
            GettoniEtichetteView(etichette: scelte)
                .padding(.vertical, 2)
        }
        Button(scelte.isEmpty ? "Aggiungi etichette" : "Cambia etichette", systemImage: "number") {
            aperto = true
        }
        .sheet(isPresented: $aperto) {
            SceltaEtichetteView(dispensa: dispensa, selezione: $selezione)
        }
    }
}

/// Elenco delle etichette della dispensa con una spunta su quelle scelte.
private struct SceltaEtichetteView: View {
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    @Binding var selezione: Set<UUID>

    @State private var mostraNuova = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(dispensa.etichetteOrdinate) { etichetta in
                        riga(etichetta)
                    }
                } footer: {
                    if dispensa.etichette?.isEmpty ?? true {
                        Text("Non ci sono ancora etichette: creane una.")
                    }
                }
                Section {
                    Button("Nuova etichetta…", systemImage: "plus") { mostraNuova = true }
                }
            }
            .navigationTitle("Etichette")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .sheet(isPresented: $mostraNuova) {
                // L'etichetta appena creata viene scelta subito.
                EtichettaFormView(dispensa: dispensa) { nuova in
                    selezione.insert(nuova.id)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 340, minHeight: 380)
#endif
    }

    private func riga(_ etichetta: Etichetta) -> some View {
        let scelta = selezione.contains(etichetta.id)
        return Button {
            if scelta {
                selezione.remove(etichetta.id)
            } else {
                selezione.insert(etichetta.id)
            }
        } label: {
            HStack {
                GettoneEtichettaView(etichetta)
                Spacer()
                if scelta {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(scelta ? .isSelected : [])
    }
}
