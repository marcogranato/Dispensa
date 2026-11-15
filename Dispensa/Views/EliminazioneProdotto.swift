//
//  EliminazioneProdotto.swift
//  Dispensa
//

import SwiftUI
import SwiftData

extension View {
    /// Gestisce la richiesta di eliminare un prodotto, condivisa da elenco e scheda del prodotto:
    /// rifiuta se ha articoli presenti, chiede conferma se ha articoli nello storico, altrimenti elimina subito.
    /// Basta assegnare il prodotto a `richiesta`.
    func eliminazioneProdotto(_ richiesta: Binding<Prodotto?>) -> some View {
        modifier(ModificatoreEliminazioneProdotto(richiesta: richiesta))
    }
}

private struct ModificatoreEliminazioneProdotto: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var richiesta: Prodotto?

    @State private var daConfermare: Prodotto?
    @State private var errore: ErroreGestioneArticoli?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, prodotto in
                guard let prodotto else { return }
                richiesta = nil
                let articoli = prodotto.articoli ?? []
                if articoli.contains(where: { $0.stato == .attivo }) {
                    errore = .prodottoConArticoliPresenti
                } else if articoli.isEmpty {
                    elimina(prodotto)
                } else {
                    daConfermare = prodotto
                }
            }
            .confirmationDialog(
                "Eliminare il prodotto?",
                isPresented: Binding(
                    get: { daConfermare != nil },
                    set: { if !$0 { daConfermare = nil } }
                ),
                titleVisibility: .visible,
                presenting: daConfermare
            ) { prodotto in
                Button("Elimina", role: .destructive) { elimina(prodotto) }
            } message: { prodotto in
                Text("Articoli di «\(prodotto.nome)» nello storico: \(prodotto.articoli?.count ?? 0). Verranno eliminati anche loro.")
            }
            .alert(
                "Impossibile eliminare",
                isPresented: Binding(
                    get: { errore != nil },
                    set: { if !$0 { errore = nil } }
                ),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore.localizedDescription)
            }
    }

    private func elimina(_ prodotto: Prodotto) {
        do {
            try modelContext.eliminaProdotto(prodotto)
        } catch let errore as ErroreGestioneArticoli {
            self.errore = errore
        } catch {
            assertionFailure("Errore inatteso: \(error)")
        }
    }
}
