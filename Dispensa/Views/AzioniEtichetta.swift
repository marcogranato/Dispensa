//
//  AzioniEtichetta.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Che cosa apre il modulo dell'etichetta.
enum ModuloEtichetta: Identifiable {
    case nuova
    case modifica(Etichetta)

    var id: String {
        switch self {
        case .nuova: "nuova"
        case .modifica(let etichetta): "modifica-\(etichetta.id.uuidString)"
        }
    }
}

extension View {
    /// Apre il modulo dell'etichetta quando `modulo` non è `nil` (condiviso da elenco e scheda).
    func moduloEtichetta(_ modulo: Binding<ModuloEtichetta?>, dispensa: Dispensa?) -> some View {
        sheet(item: modulo) { modulo in
            if let dispensa {
                switch modulo {
                case .nuova:
                    EtichettaFormView(dispensa: dispensa)
                case .modifica(let etichetta):
                    EtichettaFormView(dispensa: dispensa, etichetta: etichetta)
                }
            }
        }
    }

    /// Gestisce la richiesta di eliminare un'etichetta, condivisa da elenco e scheda:
    /// chiede conferma se è usata da qualche prodotto, altrimenti elimina subito.
    func eliminazioneEtichetta(_ richiesta: Binding<Etichetta?>) -> some View {
        modifier(ModificatoreEliminazioneEtichetta(richiesta: richiesta))
    }
}

private struct ModificatoreEliminazioneEtichetta: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var richiesta: Etichetta?

    @State private var daConfermare: Etichetta?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, etichetta in
                guard let etichetta else { return }
                richiesta = nil
                if etichetta.prodotti?.isEmpty ?? true {
                    modelContext.eliminaEtichetta(etichetta)
                } else {
                    daConfermare = etichetta
                }
            }
            .confirmationDialog(
                "Eliminare l'etichetta?",
                isPresented: Binding(
                    get: { daConfermare != nil },
                    set: { if !$0 { daConfermare = nil } }
                ),
                titleVisibility: .visible,
                presenting: daConfermare
            ) { etichetta in
                Button("Elimina", role: .destructive) { modelContext.eliminaEtichetta(etichetta) }
            } message: { etichetta in
                Text("«\(etichetta.nomeConCancelletto)» verrà tolta dai prodotti che la usano: \(etichetta.prodotti?.count ?? 0). I prodotti restano.")
            }
    }
}
