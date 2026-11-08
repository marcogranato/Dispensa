//
//  RootView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Schermata principale: una barra a schede (Strutture, Articoli, Prodotti, Storico) della dispensa aperta.
/// Su iPhone le schede sono in basso; su iPad e Mac possono diventare una barra laterale.
/// La dispensa si cambia dal menu nel titolo (`MenuDispensa`).
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dispensa.nome) private var dispense: [Dispensa]

    /// Identificativo della dispensa aperta, ricordato tra un avvio e l'altro.
    @AppStorage("dispensaCorrente") private var idDispensaCorrente = ""
    @State private var scheda = Scheda.strutture

    @State private var mostraNuovaDispensa = false
    @State private var dispensaInModifica: Dispensa?
    @State private var dispensaDaEliminare: Dispensa?

    enum Scheda: Hashable {
        case strutture, articoli, prodotti, storico
    }

    /// La dispensa ricordata; se non esiste più, la prima in ordine alfabetico.
    private var dispensaCorrente: Dispensa? {
        dispense.first { $0.id.uuidString == idDispensaCorrente } ?? dispense.first
    }

    var body: some View {
        Group {
            if let dispensa = dispensaCorrente {
                schede(dispensa)
                    // Cambiando dispensa, la navigazione di ogni scheda riparte da capo.
                    // Si usa `id` e non `persistentModelID`, che per un oggetto nuovo cambia al primo salvataggio.
                    .id(dispensa.id)
            } else {
                nessunaDispensa
            }
        }
        .sheet(isPresented: $mostraNuovaDispensa) {
            DispensaFormView { nuova in
                idDispensaCorrente = nuova.id.uuidString
            }
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
            Button("Elimina", role: .destructive) { modelContext.delete(dispensa) }
        } message: { dispensa in
            Text("Verranno eliminati anche strutture, articoli e storico di «\(dispensa.nome)». L'operazione non si può annullare.")
        }
    }

    private func schede(_ dispensa: Dispensa) -> some View {
        TabView(selection: $scheda) {
            Tab("Strutture", systemImage: "cabinet", value: Scheda.strutture) {
                NavigationStack {
                    ElencoStruttureView(dispensa: dispensa)
                        .toolbar { menuDispensa(dispensa) }
                }
            }
            Tab("Articoli", systemImage: "list.bullet", value: Scheda.articoli) {
                NavigationStack {
                    ElencoArticoliView(dispensa: dispensa)
                        .toolbar { menuDispensa(dispensa) }
                }
            }
            Tab("Prodotti", systemImage: "carrot", value: Scheda.prodotti) {
                NavigationStack {
                    ElencoProdottiView(dispensa: dispensa)
                        .toolbar { menuDispensa(dispensa) }
                }
            }
            Tab("Storico", systemImage: "clock.arrow.circlepath", value: Scheda.storico) {
                NavigationStack {
                    StoricoView(dispensa: dispensa)
                        .toolbar { menuDispensa(dispensa) }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    @ToolbarContentBuilder
    private func menuDispensa(_ dispensa: Dispensa) -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            MenuDispensa(
                dispense: dispense,
                corrente: dispensa,
                scegli: { idDispensaCorrente = $0.id.uuidString },
                nuova: { mostraNuovaDispensa = true },
                modifica: { dispensaInModifica = dispensa },
                elimina: { dispensaDaEliminare = dispensa }
            )
        }
    }

    private var nessunaDispensa: some View {
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

#Preview {
    RootView()
        .modelContainer(.anteprima)
}
