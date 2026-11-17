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
    /// Chiamato con la categoria appena creata (es. per sceglierla subito nel modulo dell'articolo).
    let alSalvataggio: ((Categoria) -> Void)?

    @State private var nome: String
    @State private var icona: String
    @State private var genitore: Categoria?
    @State private var errore: ErroreGestioneCategorie?

    init(
        dispensa: Dispensa,
        categoria: Categoria? = nil,
        genitore: Categoria? = nil,
        alSalvataggio: ((Categoria) -> Void)? = nil
    ) {
        self.dispensa = dispensa
        self.categoria = categoria
        self.alSalvataggio = alSalvataggio
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
                    SelettoreEmoji(titolo: "Emoji", selezione: $icona, ereditata: genitore?.iconaEffettiva)
                } footer: {
                    if icona.isEmpty, let ereditata = genitore?.iconaEffettiva {
                        Text("Senza emoji si usa quella della categoria superiore: \(ereditata)")
                    }
                }

                Section {
                    PickerCategoria(
                        titolo: "Dentro",
                        selezione: $genitore,
                        categorie: genitoriPossibili,
                        etichettaNessuna: "Nessuna (categoria principale)"
                    )
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
                let nuova = try modelContext.creaCategoria(nome: nome, icona: icona, sotto: genitore, in: dispensa)
                alSalvataggio?(nuova)
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
