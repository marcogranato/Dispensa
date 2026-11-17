//
//  CategorieView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Valore di navigazione per aprire l'elenco delle categorie di una dispensa (vedi `PilaDiNavigazione`).
struct ElencoCategorie: Hashable {
    let dispensa: Dispensa
}

/// Albero delle categorie dei prodotti di una dispensa, aperto dalla scheda Prodotti.
/// Il clic su una categoria apre la sua scheda; modifica ed eliminazione anche da scorrimento e menu contestuale.
struct CategorieView: View {
    let dispensa: Dispensa

    @State private var modulo: ModuloCategoria?
    @State private var categoriaDaEliminare: Categoria?

    var body: some View {
        List {
            ForEach(dispensa.categorieInOrdine) { categoria in
                RigaNavigabile(valore: categoria) {
                    RigaCategoriaView(categoria: categoria, rientrata: true)
                }
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
                        dispensa.modelContext?.inserisciCategorieDiProva(in: dispensa)
                    } label: {
                        Text(verbatim: "Aggiungi categorie di prova")
                    }
#endif
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuova categoria", systemImage: "plus") { modulo = .nuova(genitore: nil) }
            }
        }
        .moduloCategoria($modulo, dispensa: dispensa)
        .eliminazioneCategoria($categoriaDaEliminare)
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
        Button("Elimina", systemImage: "trash", role: .destructive) { categoriaDaEliminare = categoria }
    }
}

/// Riga di una categoria: emoji (o cartella), nome e numero di prodotti, sottocategorie comprese.
struct RigaCategoriaView: View {
    let categoria: Categoria
    /// Rientro in base al livello, per mostrare l'albero in un unico elenco.
    var rientrata = false

    var body: some View {
        let prodotti = categoria.prodottiCompresi.count
        HStack {
            Group {
                if let icona = categoria.iconaEffettiva {
                    Text(icona)
                } else {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 24)
            .accessibilityHidden(true)

            Text(categoria.nome)
                .foregroundStyle(.primary)
            Spacer()
            Text(prodotti, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(Text("Prodotti: \(prodotti)"))
        }
        .padding(.leading, rientrata ? CGFloat(categoria.livello - 1) * 24 : 0)
    }
}

/// Che cosa apre il modulo della categoria.
enum ModuloCategoria: Identifiable {
    case nuova(genitore: Categoria?)
    case modifica(Categoria)

    var id: String {
        switch self {
        case .nuova(let genitore): "nuova-\(genitore?.id.uuidString ?? "principale")"
        case .modifica(let categoria): "modifica-\(categoria.id.uuidString)"
        }
    }
}

extension View {
    /// Apre il modulo della categoria quando `modulo` non è `nil`.
    func moduloCategoria(_ modulo: Binding<ModuloCategoria?>, dispensa: Dispensa?) -> some View {
        sheet(item: modulo) { modulo in
            if let dispensa {
                switch modulo {
                case .nuova(let genitore):
                    CategoriaFormView(dispensa: dispensa, genitore: genitore)
                case .modifica(let categoria):
                    CategoriaFormView(dispensa: dispensa, categoria: categoria)
                }
            }
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        CategorieView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
