//
//  CategorieView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Gestione dell'albero delle categorie dei prodotti di una dispensa.
struct CategorieView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa

    @State private var modulo: Modulo?
    @State private var categoriaDaEliminare: Categoria?

    /// Che cosa apre il modulo della categoria.
    private enum Modulo: Identifiable {
        case nuova(genitore: Categoria?)
        case modifica(Categoria)

        var id: String {
            switch self {
            case .nuova(let genitore): "nuova-\(genitore?.id.uuidString ?? "principale")"
            case .modifica(let categoria): "modifica-\(categoria.id.uuidString)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(dispensa.categorieInOrdine) { categoria in
                    riga(categoria)
                }
            }
            .navigationTitle("Categorie")
            .overlay {
                if dispensa.categorie?.isEmpty ?? true {
                    ContentUnavailableView {
                        Label("Nessuna categoria", systemImage: "list.bullet.indent")
                    } description: {
                        Text("Le categorie raggruppano i prodotti, fino a tre livelli: per esempio Pasta e riso ▸ Pasta secca ▸ Pasta di semola.")
                    } actions: {
                        Button("Aggiungi una categoria") { modulo = .nuova(genitore: nil) }
                            .buttonStyle(.borderedProminent)
#if DEBUG
                        // Solo nella versione di sviluppo: niente traduzione.
                        Button {
                            modelContext.inserisciCategorieDiProva(in: dispensa)
                        } label: {
                            Text(verbatim: "Aggiungi categorie di prova")
                        }
#endif
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Nuova categoria", systemImage: "plus") { modulo = .nuova(genitore: nil) }
                }
            }
            .sheet(item: $modulo) { modulo in
                switch modulo {
                case .nuova(let genitore):
                    CategoriaFormView(dispensa: dispensa, genitore: genitore)
                case .modifica(let categoria):
                    CategoriaFormView(dispensa: dispensa, categoria: categoria)
                }
            }
            .confirmationDialog(
                "Eliminare la categoria?",
                isPresented: Binding(
                    get: { categoriaDaEliminare != nil },
                    set: { if !$0 { categoriaDaEliminare = nil } }
                ),
                titleVisibility: .visible,
                presenting: categoriaDaEliminare
            ) { categoria in
                Button("Elimina", role: .destructive) { modelContext.eliminaCategoria(categoria) }
            } message: { categoria in
                messaggioEliminazione(categoria)
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 400)
#endif
    }

    private func riga(_ categoria: Categoria) -> some View {
        HStack {
            Group {
                if let icona = categoria.icona {
                    Text(icona)
                } else {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 24)
            .accessibilityHidden(true)

            Text(categoria.nome)
            Spacer()
            let prodotti = numeroProdotti(categoria)
            Text(prodotti, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(Text("Prodotti: \(prodotti)"))
        }
        .padding(.leading, CGFloat(categoria.livello - 1) * 24)
        .contentShape(Rectangle())
        .contextMenu {
            pulsanteAggiungiSottocategoria(categoria)
            pulsanteModifica(categoria)
            pulsanteElimina(categoria)
        }
        .swipeActions {
            pulsanteElimina(categoria)
            pulsanteModifica(categoria)
        }
        .swipeActions(edge: .leading) {
            pulsanteAggiungiSottocategoria(categoria)
        }
    }

    @ViewBuilder
    private func pulsanteAggiungiSottocategoria(_ categoria: Categoria) -> some View {
        if categoria.livello < Categoria.livelliMassimi {
            Button("Aggiungi sottocategoria", systemImage: "plus") { modulo = .nuova(genitore: categoria) }
                .tint(.green)
        }
    }

    private func pulsanteModifica(_ categoria: Categoria) -> some View {
        Button("Modifica", systemImage: "pencil") { modulo = .modifica(categoria) }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ categoria: Categoria) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) {
            // Si chiede conferma solo se si perde qualcos'altro o se dei prodotti cambiano categoria.
            if categoria.discendenti.isEmpty && numeroProdotti(categoria) == 0 {
                modelContext.eliminaCategoria(categoria)
            } else {
                categoriaDaEliminare = categoria
            }
        }
    }

    /// Prodotti della categoria e di tutte le sue sottocategorie.
    private func numeroProdotti(_ categoria: Categoria) -> Int {
        ([categoria] + categoria.discendenti).reduce(0) { $0 + ($1.prodotti?.count ?? 0) }
    }

    private func messaggioEliminazione(_ categoria: Categoria) -> Text {
        let sottocategorie = categoria.discendenti.count
        let prodotti = numeroProdotti(categoria)
        if let genitore = categoria.genitore {
            return Text("Sottocategorie eliminate insieme: \(sottocategorie). Prodotti che passeranno a «\(genitore.nome)»: \(prodotti).")
        } else {
            return Text("Sottocategorie eliminate insieme: \(sottocategorie). Prodotti che resteranno senza categoria: \(prodotti).")
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    CategorieView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
