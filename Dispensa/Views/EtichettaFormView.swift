//
//  EtichettaFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare o modificare un'etichetta: nome (senza "#") e colore facoltativo.
struct EtichettaFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    /// `nil` per creare una nuova etichetta.
    let etichetta: Etichetta?
    /// Chiamato con l'etichetta appena creata (es. per sceglierla subito nel modulo del prodotto).
    let alSalvataggio: ((Etichetta) -> Void)?

    @State private var nome: String
    @State private var colore: ColoreEtichetta?
    @State private var errore: ErroreGestioneEtichette?

    init(dispensa: Dispensa, etichetta: Etichetta? = nil, alSalvataggio: ((Etichetta) -> Void)? = nil) {
        self.dispensa = dispensa
        self.etichetta = etichetta
        self.alSalvataggio = alSalvataggio
        _nome = State(initialValue: etichetta?.nome ?? "")
        _colore = State(initialValue: etichetta?.colore)
    }

    private var nomeNormalizzato: String { Etichetta.nomeNormalizzato(nome) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $nome, prompt: Text("Es. colazione, senzaglutine"))
                        .autocorrectionDisabled()
#if os(iOS)
                        .textInputAutocapitalization(.never)
#endif
                } footer: {
                    Text("Il cancelletto si aggiunge da solo; gli spazi vengono tolti.")
                }

                Section("Colore") {
                    tavolozza
                }

                if !nomeNormalizzato.isEmpty {
                    Section("Anteprima") {
                        GettoneEtichettaView(nome: "#\(nomeNormalizzato)", colore: colore)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(etichetta == nil ? Text("Nuova etichetta") : Text("Modifica etichetta"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nomeNormalizzato.isEmpty)
                }
            }
            .alert(
                "Impossibile salvare",
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
#if os(macOS)
        .frame(minWidth: 400, minHeight: 340)
#endif
    }

    /// "Nessuno" e un pallino per ogni colore; quello scelto ha un segno di spunta.
    private var tavolozza: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36), spacing: 10)], spacing: 10) {
            pallino(nil)
            ForEach(ColoreEtichetta.allCases) { pallino($0) }
        }
        .padding(.vertical, 4)
    }

    private func pallino(_ opzione: ColoreEtichetta?) -> some View {
        let scelto = opzione == colore
        return Button {
            colore = opzione
        } label: {
            ZStack {
                if let opzione {
                    Circle().fill(opzione.colore)
                } else {
                    Circle().strokeBorder(.secondary, lineWidth: 1.5)
                    Image(systemName: "slash.circle")
                        .foregroundStyle(.secondary)
                }
                if scelto {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(opzione == nil ? Color.primary : Color.white)
                }
            }
            .frame(width: 32, height: 32)
            .overlay {
                if scelto {
                    Circle().strokeBorder(Color.primary, lineWidth: 2).padding(-4)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(opzione.map { Text($0.nomeLocalizzato) } ?? Text("Nessun colore"))
        .accessibilityAddTraits(scelto ? .isSelected : [])
    }

    private func salva() {
        do {
            if let etichetta {
                try modelContext.modificaEtichetta(etichetta, nome: nome, colore: colore)
            } else {
                let nuova = try modelContext.creaEtichetta(nome: nome, colore: colore, in: dispensa)
                alSalvataggio?(nuova)
            }
            dismiss()
        } catch let errore as ErroreGestioneEtichette {
            self.errore = errore
        } catch {
            assertionFailure("Errore inatteso: \(error)")
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    EtichettaFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
