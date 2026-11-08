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
    @State private var strutturaSelezionata: Struttura?

    var body: some View {
        NavigationSplitView {
            ElencoDispenseView(selezione: $dispensaSelezionata)
#if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        } content: {
            if let dispensa = dispensaSelezionata {
                ElencoStruttureView(dispensa: dispensa, selezione: $strutturaSelezionata)
#if os(macOS)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 260)
#endif
            } else {
                ContentUnavailableView("Seleziona una dispensa", systemImage: "cabinet")
            }
        } detail: {
            if let struttura = strutturaSelezionata {
                DettaglioStrutturaView(struttura: struttura)
            } else {
                ContentUnavailableView("Seleziona una struttura", systemImage: "square.stack.3d.up")
            }
        }
        .onChange(of: dispensaSelezionata) {
            strutturaSelezionata = nil
        }
    }
}

#Preview {
    RootView()
        .modelContainer(.anteprima)
}
