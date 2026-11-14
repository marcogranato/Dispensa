//
//  PickerCategoria.swift
//  Dispensa
//

import SwiftUI

/// Menu per scegliere una categoria dell'albero, mostrata con il suo percorso
/// (es. "Pasta e riso ▸ Pasta secca"), più una voce per "nessuna".
struct PickerCategoria: View {
    let titolo: LocalizedStringKey
    @Binding var selezione: Categoria?
    /// Categorie tra cui scegliere, già nell'ordine in cui mostrarle.
    let categorie: [Categoria]
    let etichettaNessuna: LocalizedStringKey

    var body: some View {
        Picker(titolo, selection: $selezione) {
            Text(etichettaNessuna).tag(Categoria?.none)
            ForEach(categorie) { categoria in
                Text(categoria.percorsoTestuale).tag(Optional(categoria))
            }
        }
    }
}
