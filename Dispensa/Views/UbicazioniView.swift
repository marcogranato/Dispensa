//
//  UbicazioniView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Gestione delle ubicazioni (cucina, cantina, …) di una dispensa.
struct UbicazioniView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa

    @State private var mostraAlertNome = false
    /// Ubicazione da rinominare; `nil` quando se ne crea una nuova.
    @State private var ubicazioneInModifica: Ubicazione?
    @State private var nomeInserito = ""
    @State private var ubicazioneDaEliminare: Ubicazione?

    private static let suggerimenti: [LocalizedStringResource] = [
        "Cucina", "Cantina", "Salone", "Ripostiglio", "Garage", "Taverna", "Giardino",
    ]

    private var ubicazioni: [Ubicazione] {
        (dispensa.ubicazioni ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    private var suggerimentiDisponibili: [String] {
        Self.suggerimenti.map { String(localized: $0) }.filter { !esiste($0) }
    }

    private var nomePulito: String {
        nomeInserito.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nomeValido: Bool {
        !nomePulito.isEmpty && !esiste(nomePulito, escludendo: ubicazioneInModifica)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ubicazioni) { ubicazione in
                        riga(ubicazione)
                    }
                } footer: {
                    if ubicazioni.isEmpty {
                        Text("Nessuna ubicazione. Aggiungine una o scegli tra i suggerimenti.")
                    }
                }

                if !suggerimentiDisponibili.isEmpty {
                    Section("Suggerimenti") {
                        ForEach(suggerimentiDisponibili, id: \.self) { nome in
                            Button {
                                aggiungi(nome)
                            } label: {
                                Label(nome, systemImage: "plus.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ubicazioni")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Nuova ubicazione", systemImage: "plus") { apriAlertNome(per: nil) }
                }
            }
            .alert(
                ubicazioneInModifica == nil ? Text("Nuova ubicazione") : Text("Rinomina ubicazione"),
                isPresented: $mostraAlertNome
            ) {
                TextField("Nome", text: $nomeInserito)
                Button("Annulla", role: .cancel) {}
                Button("Salva", action: salvaNome)
                    .disabled(!nomeValido)
            }
            .confirmationDialog(
                "Eliminare l'ubicazione?",
                isPresented: Binding(
                    get: { ubicazioneDaEliminare != nil },
                    set: { if !$0 { ubicazioneDaEliminare = nil } }
                ),
                titleVisibility: .visible,
                presenting: ubicazioneDaEliminare
            ) { ubicazione in
                Button("Elimina", role: .destructive) { modelContext.delete(ubicazione) }
            } message: { ubicazione in
                let numero = ubicazione.strutture?.count ?? 0
                Text("Strutture collegate: \(numero). Non verranno eliminate, ma resteranno senza ubicazione.")
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
#endif
    }

    private func riga(_ ubicazione: Ubicazione) -> some View {
        HStack {
            Label(ubicazione.nome, systemImage: "mappin.and.ellipse")
            Spacer()
            Text("\(ubicazione.strutture?.count ?? 0)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .contentShape(Rectangle())
        .contextMenu {
            pulsanteRinomina(ubicazione)
            pulsanteElimina(ubicazione)
        }
        .swipeActions {
            pulsanteElimina(ubicazione)
            pulsanteRinomina(ubicazione)
        }
    }

    private func pulsanteRinomina(_ ubicazione: Ubicazione) -> some View {
        Button("Rinomina", systemImage: "pencil") { apriAlertNome(per: ubicazione) }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ ubicazione: Ubicazione) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) {
            if ubicazione.strutture?.isEmpty ?? true {
                modelContext.delete(ubicazione)
            } else {
                ubicazioneDaEliminare = ubicazione
            }
        }
    }

    private func apriAlertNome(per ubicazione: Ubicazione?) {
        ubicazioneInModifica = ubicazione
        nomeInserito = ubicazione?.nome ?? ""
        mostraAlertNome = true
    }

    private func salvaNome() {
        guard nomeValido else { return }
        if let ubicazioneInModifica {
            ubicazioneInModifica.nome = nomePulito
        } else {
            aggiungi(nomePulito)
        }
    }

    private func aggiungi(_ nome: String) {
        let ubicazione = Ubicazione(nome: nome)
        modelContext.insert(ubicazione)
        ubicazione.dispensa = dispensa
    }

    /// Vero se nella dispensa esiste già un'ubicazione con questo nome (senza distinguere maiuscole).
    private func esiste(_ nome: String, escludendo esclusa: Ubicazione? = nil) -> Bool {
        (dispensa.ubicazioni ?? []).contains {
            $0 !== esclusa && $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    UbicazioniView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
