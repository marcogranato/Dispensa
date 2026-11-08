//
//  AzioniArticolo.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Un'azione richiesta su un articolo, che apre il relativo modulo.
struct AzioneArticolo: Identifiable {
    enum Tipo {
        case preleva, butta, sposta, modifica
    }

    let tipo: Tipo
    let articolo: Articolo
    let id = UUID()
}

/// Pulsanti delle azioni su un articolo, usati nei menu contestuali.
struct MenuAzioniArticolo: View {
    let articolo: Articolo
    @Binding var azione: AzioneArticolo?
    @Binding var daEliminare: Articolo?

    var body: some View {
        Button("Preleva…", systemImage: "minus.circle") { azione = AzioneArticolo(tipo: .preleva, articolo: articolo) }
        Button("Butta…", systemImage: "trash.slash") { azione = AzioneArticolo(tipo: .butta, articolo: articolo) }
        Button("Sposta…", systemImage: "arrow.right.circle") { azione = AzioneArticolo(tipo: .sposta, articolo: articolo) }
        Divider()
        Button("Modifica", systemImage: "pencil") { azione = AzioneArticolo(tipo: .modifica, articolo: articolo) }
        Button("Elimina", systemImage: "trash", role: .destructive) { daEliminare = articolo }
    }
}

extension View {
    /// Collega i moduli delle azioni e la conferma di eliminazione di un articolo.
    func azioniArticolo(_ azione: Binding<AzioneArticolo?>, daEliminare: Binding<Articolo?>) -> some View {
        modifier(ModificatoreAzioniArticolo(azione: azione, daEliminare: daEliminare))
    }
}

private struct ModificatoreAzioniArticolo: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Binding var azione: AzioneArticolo?
    @Binding var daEliminare: Articolo?

    func body(content: Content) -> some View {
        content
            .sheet(item: $azione) { azione in
                switch azione.tipo {
                case .modifica:
                    if let dispensa = azione.articolo.dispensa {
                        ArticoloFormView(dispensa: dispensa, struttura: azione.articolo.struttura, articolo: azione.articolo)
                    }
                case .preleva, .butta, .sposta:
                    AzioneArticoloView(azione: azione)
                }
            }
            .confirmationDialog(
                "Eliminare l'articolo?",
                isPresented: Binding(
                    get: { daEliminare != nil },
                    set: { if !$0 { daEliminare = nil } }
                ),
                titleVisibility: .visible,
                presenting: daEliminare
            ) { articolo in
                Button("Elimina", role: .destructive) { modelContext.delete(articolo) }
            } message: { _ in
                Text("Usa Elimina solo per un articolo inserito per errore: non finirà nello storico. Per il cibo consumato o buttato usa Preleva o Butta.")
            }
    }
}

/// Modulo per prelevare, buttare o spostare alcune parti di un articolo.
struct AzioneArticoloView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let azione: AzioneArticolo

    @State private var parti: Int
    @State private var motivo: MotivoScarto
    @State private var destinazione: Struttura?
    @State private var errore: String?

    init(azione: AzioneArticolo) {
        self.azione = azione
        let articolo = azione.articolo
        // Si preleva di solito una parte alla volta; si butta o si sposta di solito tutto.
        _parti = State(initialValue: azione.tipo == .preleva ? 1 : articolo.partiRimaste)
        _motivo = State(initialValue: articolo.statoScadenza() == .scaduto ? .scaduto : .avariato)
        _destinazione = State(initialValue: nil)
    }

    private var articolo: Articolo { azione.articolo }

    private var altreStrutture: [Struttura] {
        (articolo.dispensa?.strutture ?? [])
            .filter { $0 !== articolo.struttura }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    private var titolo: Text {
        switch azione.tipo {
        case .preleva: Text("Preleva")
        case .butta: Text("Butta")
        case .sposta: Text("Sposta")
        case .modifica: Text("Modifica")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    RigaArticoloView(articolo: articolo)
                }

                if articolo.partiRimaste > 1 {
                    Section {
                        Stepper(value: $parti, in: 1...articolo.partiRimaste) {
                            LabeledContent("Parti") {
                                Text("\(parti) di \(articolo.partiRimaste)")
                            }
                        }
                    } footer: {
                        piePagina
                    }
                }

                if azione.tipo == .butta {
                    Picker("Motivo", selection: $motivo) {
                        ForEach(MotivoScarto.allCases) { motivo in
                            Text(motivo.nomeLocalizzato).tag(motivo)
                        }
                    }
                }

                if azione.tipo == .sposta {
                    if altreStrutture.isEmpty {
                        Text("Non ci sono altre strutture in questa dispensa.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Sposta in", selection: $destinazione) {
                            Text("Scegli").tag(nil as Struttura?)
                            ForEach(altreStrutture) { struttura in
                                Label(struttura.nome, systemImage: struttura.tipo.simbolo)
                                    .tag(struttura as Struttura?)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(titolo)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: esegui) { titolo }
                        .disabled(azione.tipo == .sposta && destinazione == nil)
                }
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } }),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore)
            }
        }
#if os(macOS)
        .frame(minWidth: 380, minHeight: 300)
#endif
    }

    @ViewBuilder
    private var piePagina: some View {
        let esce = parti == articolo.partiRimaste
        switch azione.tipo {
        case .preleva where esce, .butta where esce:
            if articolo.dispensa?.storicoAbilitato ?? true {
                Text("La confezione sarà vuota e passerà nello storico.")
            } else {
                Text("La confezione sarà vuota e verrà eliminata.")
            }
        case .sposta where !esce:
            Text("La confezione verrà divisa: le parti spostate diventano un nuovo articolo con le stesse date.")
        default:
            EmptyView()
        }
    }

    private func esegui() {
        do {
            switch azione.tipo {
            case .preleva:
                try modelContext.preleva(articolo, parti: parti)
            case .butta:
                try modelContext.butta(articolo, parti: parti, motivo: motivo)
            case .sposta:
                guard let destinazione else { return }
                try modelContext.sposta(articolo, in: destinazione, parti: parti)
            case .modifica:
                return
            }
            dismiss()
        } catch {
            errore = error.localizedDescription
        }
    }
}
