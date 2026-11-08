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

    enum Scheda: Hashable, CaseIterable {
        case strutture, articoli, prodotti, storico

        var titolo: LocalizedStringKey {
            switch self {
            case .strutture: "Strutture"
            case .articoli: "Articoli"
            case .prodotti: "Prodotti"
            case .storico: "Storico"
            }
        }

        var simbolo: String {
            switch self {
            case .strutture: "cabinet"
            case .articoli: "list.bullet"
            case .prodotti: "carrot"
            case .storico: "clock.arrow.circlepath"
            }
        }
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

    /// Su iPhone e iPad una `TabView`. Sul Mac una vista divisa costruita qui: la `TabView` con barra laterale
    /// del Mac condivide la navigazione tra le schede, e cambiando scheda il dettaglio aperto finiva
    /// nella scheda sbagliata o spariva lasciando una riga selezionata non più cliccabile.
    @ViewBuilder
    private func schede(_ dispensa: Dispensa) -> some View {
#if os(macOS)
        NavigationSplitView {
            List(Scheda.allCases, id: \.self, selection: Binding(
                get: { scheda },
                set: { if let nuova = $0 { scheda = nuova } }
            )) { voce in
                Label(voce.titolo, systemImage: voce.simbolo)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            pila(scheda, dispensa: dispensa)
                .id(scheda)
        }
#else
        TabView(selection: $scheda) {
            ForEach(Scheda.allCases, id: \.self) { voce in
                Tab(voce.titolo, systemImage: voce.simbolo, value: voce) {
                    pila(voce, dispensa: dispensa)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
#endif
    }

    /// La pila di navigazione di una scheda, con il suo percorso e il menu della dispensa nel titolo.
    private func pila(_ scheda: Scheda, dispensa: Dispensa) -> some View {
        PilaDiNavigazione {
            Group {
                switch scheda {
                case .strutture: ElencoStruttureView(dispensa: dispensa)
                case .articoli: ElencoArticoliView(dispensa: dispensa)
                case .prodotti: ElencoProdottiView(dispensa: dispensa)
                case .storico: StoricoView(dispensa: dispensa)
                }
            }
            .toolbar { menuDispensa(dispensa) }
        }
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
