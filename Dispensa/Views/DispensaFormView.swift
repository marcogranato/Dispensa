//
//  DispensaFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare una nuova dispensa (`dispensa == nil`) o modificarne una esistente.
/// Le modifiche vengono applicate solo premendo "Salva".
struct DispensaFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa?
    /// Chiamato con la dispensa appena creata (non in modifica), per aprirla subito.
    let creata: ((Dispensa) -> Void)?

    @State private var nome: String
    @State private var storicoAbilitato: Bool
    @State private var chiediCosaFareDelloStorico = false

    init(dispensa: Dispensa? = nil, creata: ((Dispensa) -> Void)? = nil) {
        self.dispensa = dispensa
        self.creata = creata
        _nome = State(initialValue: dispensa?.nome ?? "")
        _storicoAbilitato = State(initialValue: dispensa?.storicoAbilitato ?? true)
    }

    private var nomePulito: String {
        nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nome", text: $nome, prompt: Text("Es. Casa, Casa al mare"))

                Section {
                    Toggle("Conserva storico", isOn: $storicoAbilitato)
                } footer: {
                    Text("Gli articoli consumati o buttati restano consultabili nello storico. Se disattivato, vengono eliminati.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(dispensa == nil ? Text("Nuova dispensa") : Text("Modifica dispensa"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nomePulito.isEmpty)
                }
            }
            .confirmationDialog(
                "Disattivare lo storico?",
                isPresented: $chiediCosaFareDelloStorico,
                titleVisibility: .visible
            ) {
                Button("Elimina lo storico esistente", role: .destructive) { applica(svuotandoLoStorico: true) }
                Button("Conserva lo storico esistente") { applica(svuotandoLoStorico: false) }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Da ora gli articoli consumati o buttati verranno eliminati. Articoli già nello storico: \(dispensa?.articoliNelloStorico.count ?? 0).")
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 240)
#endif
    }

    private func salva() {
        if let dispensa, dispensa.storicoAbilitato, !storicoAbilitato, !dispensa.articoliNelloStorico.isEmpty {
            chiediCosaFareDelloStorico = true
        } else {
            applica(svuotandoLoStorico: false)
        }
    }

    private func applica(svuotandoLoStorico: Bool) {
        let dispensaDaSalvare = dispensa ?? {
            let nuova = Dispensa(nome: nomePulito)
            modelContext.insert(nuova)
            return nuova
        }()
        dispensaDaSalvare.nome = nomePulito
        dispensaDaSalvare.storicoAbilitato = storicoAbilitato
        if svuotandoLoStorico {
            modelContext.svuotaStorico(di: dispensaDaSalvare)
        }
        if dispensa == nil {
            creata?(dispensaDaSalvare)
        }
        dismiss()
    }
}

#Preview("Nuova") {
    DispensaFormView()
        .modelContainer(.anteprima)
}
