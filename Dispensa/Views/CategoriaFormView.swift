//
//  CategoriaFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare o modificare una categoria: nome, emoji e posizione nell'albero.
struct CategoriaFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    /// `nil` per creare una nuova categoria.
    let categoria: Categoria?

    @State private var nome: String
    @State private var icona: String
    @State private var genitore: Categoria?
    @State private var errore: ErroreGestioneCategorie?

    init(dispensa: Dispensa, categoria: Categoria? = nil, genitore: Categoria? = nil) {
        self.dispensa = dispensa
        self.categoria = categoria
        _nome = State(initialValue: categoria?.nome ?? "")
        _icona = State(initialValue: categoria?.icona ?? "")
        _genitore = State(initialValue: categoria?.genitore ?? genitore)
    }

    /// Categorie che possono contenerla: non sé stessa né le sue sottocategorie,
    /// e senza superare i tre livelli insieme alle sue sottocategorie.
    private var genitoriPossibili: [Categoria] {
        let altezza = categoria?.altezza ?? 1
        let esclusi = Set(([categoria].compactMap { $0 } + (categoria?.discendenti ?? [])).map(\.id))
        return dispensa.categorieInOrdine.filter {
            !esclusi.contains($0.id) && $0.livello + altezza <= Categoria.livelliMassimi
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $nome)
                    TextField("Emoji (facoltativa)", text: $icona)
                        .onChange(of: icona) { _, nuovo in
                            let ridotta = Categoria.iconaNormalizzata(nuovo) ?? ""
                            if ridotta != nuovo { icona = ridotta }
                        }
                } footer: {
                    if icona.isEmpty, let ereditata = genitore?.iconaEffettiva {
                        Text("Senza emoji si usa quella della categoria superiore: \(ereditata)")
                    }
                }

                Section {
                    Picker("Dentro", selection: $genitore) {
                        Text("Nessuna (categoria principale)").tag(Categoria?.none)
                        ForEach(genitoriPossibili) { possibile in
                            Text(possibile.percorso.map(\.nome).joined(separator: " ▸ "))
                                .tag(Optional(possibile))
                        }
                    }
                } footer: {
                    Text("Fino a tre livelli: categoria, sottocategoria e tipologia.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(categoria == nil ? Text("Nuova categoria") : Text("Modifica categoria"))
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .frame(minWidth: 400, minHeight: 300)
#endif
    }

    private func salva() {
        do {
            if let categoria {
                try modelContext.modificaCategoria(categoria, nome: nome, icona: icona, sotto: genitore)
            } else {
                try modelContext.creaCategoria(nome: nome, icona: icona, sotto: genitore, in: dispensa)
            }
            dismiss()
        } catch let errore as ErroreGestioneCategorie {
            self.errore = errore
        } catch {
            assertionFailure("Errore inatteso: \(error)")
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    CategoriaFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
