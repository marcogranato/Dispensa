//
//  EliminazioneCategoria.swift
//  Dispensa
//

import SwiftUI
import SwiftData

extension View {
    /// Gestisce la richiesta di eliminare una categoria, condivisa da elenco e scheda della categoria:
    /// chiede conferma se ha sottocategorie o prodotti, altrimenti elimina subito.
    /// Basta assegnare la categoria a `richiesta`.
    func eliminazioneCategoria(_ richiesta: Binding<Categoria?>) -> some View {
        modifier(ModificatoreEliminazioneCategoria(richiesta: richiesta))
    }
}

private struct ModificatoreEliminazioneCategoria: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var richiesta: Categoria?

    @State private var daConfermare: Categoria?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, categoria in
                guard let categoria else { return }
                richiesta = nil
                if categoria.discendenti.isEmpty && categoria.prodottiCompresi.isEmpty {
                    modelContext.eliminaCategoria(categoria)
                } else {
                    daConfermare = categoria
                }
            }
            .confirmationDialog(
                "Eliminare la categoria?",
                isPresented: Binding(
                    get: { daConfermare != nil },
                    set: { if !$0 { daConfermare = nil } }
                ),
                titleVisibility: .visible,
                presenting: daConfermare
            ) { categoria in
                Button("Elimina", role: .destructive) { modelContext.eliminaCategoria(categoria) }
            } message: { categoria in
                messaggio(categoria)
            }
    }

    private func messaggio(_ categoria: Categoria) -> Text {
        let sottocategorie = categoria.discendenti.count
        let prodotti = categoria.prodottiCompresi.count
        if let genitore = categoria.genitore {
            return Text("Sottocategorie eliminate insieme: \(sottocategorie). Prodotti che passeranno a «\(genitore.nome)»: \(prodotti).")
        } else {
            return Text("Sottocategorie eliminate insieme: \(sottocategorie). Prodotti che resteranno senza categoria: \(prodotti).")
        }
    }
}
