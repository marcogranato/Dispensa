//
//  FiltriProdottiView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Foglio con i filtri della scheda Prodotti. Le modifiche valgono subito; "Fine" chiude.
struct FiltriProdottiView: View {
    let dispensa: Dispensa
    @Binding var filtro: FiltroProdotti

    var body: some View {
        FoglioFiltri(filtro: $filtro) {
            SezioneFiltroCategorie(dispensa: dispensa, selezione: $filtro.categorie)
            SezioneFiltroEtichette(dispensa: dispensa, selezione: $filtro.etichette)
            Section {
                ForEach(PresenzaProdotto.allCases) { presenza in
                    RigaConSpunta(selezione: $filtro.presenze, valore: presenza) {
                        Label { Text(presenza.nomeLocalizzato) } icon: { Image(systemName: presenza.simbolo) }
                    }
                }
            } header: {
                Text("Articoli presenti")
            } footer: {
                Text("«Senza articoli» trova i prodotti finiti, da ricomprare.")
            }
        }
    }
}
