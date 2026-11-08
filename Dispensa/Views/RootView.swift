//
//  RootView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Schermata principale a tre colonne: Dispense → Strutture → dettaglio.
/// Su iPhone `NavigationSplitView` diventa automaticamente una navigazione a pagine.
struct RootView: View {
    @State private var dispensaSelezionata: Dispensa?
    @State private var mostraUbicazioni = false

    var body: some View {
        NavigationSplitView {
            ElencoDispenseView(selezione: $dispensaSelezionata)
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        } content: {
            if let dispensa = dispensaSelezionata {
                ContentUnavailableView("Nessuna struttura", systemImage: "square.stack.3d.up")
                    .navigationTitle(dispensa.nome)
                    .toolbar {
                        ToolbarItem {
                            Button("Ubicazioni", systemImage: "mappin.and.ellipse") { mostraUbicazioni = true }
                        }
                    }
                    .sheet(isPresented: $mostraUbicazioni) {
                        UbicazioniView(dispensa: dispensa)
                    }
            } else {
                ContentUnavailableView("Seleziona una dispensa", systemImage: "cabinet")
            }
        } detail: {
            ContentUnavailableView("Seleziona una struttura", systemImage: "square.stack.3d.up")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(.anteprima)
}
