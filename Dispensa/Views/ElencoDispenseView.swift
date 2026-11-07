//
//  ElencoDispenseView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Elenco di tutte le dispense, con creazione, modifica ed eliminazione.
struct ElencoDispenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dispensa.nome) private var dispense: [Dispensa]

    @Binding var selezione: Dispensa?

    @State private var mostraNuovaDispensa = false
    @State private var dispensaInModifica: Dispensa?
    @State private var dispensaDaEliminare: Dispensa?

    var body: some View {
        List(selection: $selezione) {
            ForEach(dispense) { dispensa in
                NavigationLink(value: dispensa) {
                    Label(dispensa.nome, systemImage: "house")
                }
                .contextMenu {
                    pulsanteModifica(dispensa)
                    pulsanteElimina(dispensa)
                }
                .swipeActions {
                    pulsanteElimina(dispensa)
                    pulsanteModifica(dispensa)
                }
            }
        }
        .navigationTitle("Dispense")
        .overlay {
            if dispense.isEmpty {
                ContentUnavailableView {
                    Label("Nessuna dispensa", systemImage: "cabinet")
                } description: {
                    Text("Crea una dispensa per iniziare a organizzare frigorifero, scaffali e tutto il resto.")
                } actions: {
                    Button("Crea la tua prima dispensa") { mostraNuovaDispensa = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuova dispensa", systemImage: "plus") { mostraNuovaDispensa = true }
            }
        }
        .sheet(isPresented: $mostraNuovaDispensa) {
            DispensaFormView()
        }
        .sheet(item: $dispensaInModifica) { dispensa in
            DispensaFormView(dispensa: dispensa)
        }
        .confirmationDialog(
            "Eliminare la dispensa?",
            isPresented: Binding(
                get: { dispensaDaEliminare != nil },
                set: { if !$0 { dispensaDaEliminare = nil } }
            ),
            titleVisibility: .visible,
            presenting: dispensaDaEliminare
        ) { dispensa in
            Button("Elimina", role: .destructive) { elimina(dispensa) }
        } message: { dispensa in
            Text("Verranno eliminati anche strutture, articoli e storico di «\(dispensa.nome)». L'operazione non si può annullare.")
        }
    }

    private func pulsanteModifica(_ dispensa: Dispensa) -> some View {
        Button("Modifica", systemImage: "pencil") { dispensaInModifica = dispensa }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ dispensa: Dispensa) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) { dispensaDaEliminare = dispensa }
    }

    private func elimina(_ dispensa: Dispensa) {
        if selezione == dispensa {
            selezione = nil
        }
        modelContext.delete(dispensa)
    }
}

#Preview {
    @Previewable @State var selezione: Dispensa?
    NavigationStack {
        ElencoDispenseView(selezione: $selezione)
    }
    .modelContainer(.anteprima)
}
