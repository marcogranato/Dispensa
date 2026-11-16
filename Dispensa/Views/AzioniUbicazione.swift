//
//  AzioniUbicazione.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Che cosa apre la richiesta del nome di un'ubicazione.
enum NomeUbicazione: Identifiable {
    case nuova
    case rinomina(Ubicazione)

    var id: String {
        switch self {
        case .nuova: "nuova"
        case .rinomina(let ubicazione): "rinomina-\(ubicazione.id.uuidString)"
        }
    }
}

extension Dispensa {
    /// Ubicazioni in ordine alfabetico.
    var ubicazioniOrdinate: [Ubicazione] {
        (ubicazioni ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    /// Vero se esiste già un'ubicazione con questo nome (senza distinguere maiuscole e accenti).
    func esisteUbicazione(nominata nome: String, escludendo esclusa: Ubicazione? = nil) -> Bool {
        (ubicazioni ?? []).contains {
            $0 !== esclusa && $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}

extension ModelContext {
    /// Crea un'ubicazione nella dispensa.
    func aggiungiUbicazione(nominata nome: String, in dispensa: Dispensa) {
        let ubicazione = Ubicazione(nome: nome)
        insert(ubicazione)
        ubicazione.dispensa = dispensa
    }
}

extension View {
    /// Chiede il nome di una nuova ubicazione o il nuovo nome di una esistente, quando `richiesta` non è `nil`.
    func nomeUbicazione(_ richiesta: Binding<NomeUbicazione?>, dispensa: Dispensa?) -> some View {
        modifier(ModificatoreNomeUbicazione(richiesta: richiesta, dispensa: dispensa))
    }

    /// Gestisce la richiesta di eliminare un'ubicazione, condivisa da elenco e scheda dell'ubicazione:
    /// chiede conferma se ha strutture collegate, altrimenti elimina subito.
    func eliminazioneUbicazione(_ richiesta: Binding<Ubicazione?>) -> some View {
        modifier(ModificatoreEliminazioneUbicazione(richiesta: richiesta))
    }
}

private struct ModificatoreNomeUbicazione: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var richiesta: NomeUbicazione?
    let dispensa: Dispensa?

    @State private var mostraAlert = false
    @State private var inModifica: Ubicazione?
    @State private var nomeInserito = ""

    private var nomePulito: String {
        nomeInserito.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nomeValido: Bool {
        guard let dispensa, !nomePulito.isEmpty else { return false }
        return !dispensa.esisteUbicazione(nominata: nomePulito, escludendo: inModifica)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta?.id) {
                guard let valore = richiesta else { return }
                richiesta = nil
                switch valore {
                case .nuova: inModifica = nil
                case .rinomina(let ubicazione): inModifica = ubicazione
                }
                nomeInserito = inModifica?.nome ?? ""
                mostraAlert = true
            }
            .alert(
                inModifica == nil ? Text("Nuova ubicazione") : Text("Rinomina ubicazione"),
                isPresented: $mostraAlert
            ) {
                TextField("Nome", text: $nomeInserito)
                Button("Annulla", role: .cancel) {}
                Button("Salva", action: salva)
                    .disabled(!nomeValido)
            }
    }

    private func salva() {
        guard nomeValido, let dispensa else { return }
        if let inModifica {
            inModifica.nome = nomePulito
        } else {
            modelContext.aggiungiUbicazione(nominata: nomePulito, in: dispensa)
        }
    }
}

private struct ModificatoreEliminazioneUbicazione: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var richiesta: Ubicazione?

    @State private var daConfermare: Ubicazione?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, ubicazione in
                guard let ubicazione else { return }
                richiesta = nil
                if ubicazione.strutture?.isEmpty ?? true {
                    modelContext.delete(ubicazione)
                } else {
                    daConfermare = ubicazione
                }
            }
            .confirmationDialog(
                "Eliminare l'ubicazione?",
                isPresented: Binding(
                    get: { daConfermare != nil },
                    set: { if !$0 { daConfermare = nil } }
                ),
                titleVisibility: .visible,
                presenting: daConfermare
            ) { ubicazione in
                Button("Elimina", role: .destructive) { modelContext.delete(ubicazione) }
            } message: { ubicazione in
                let numero = ubicazione.strutture?.count ?? 0
                Text("Strutture collegate: \(numero). Non verranno eliminate, ma resteranno senza ubicazione.")
            }
    }
}
