//
//  DettaglioCategoriaView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Scheda di una categoria in sola lettura: percorso, emoji, sottocategorie e prodotti
/// (anche quelli delle sottocategorie). Si modifica con il pulsante "Modifica".
struct DettaglioCategoriaView: View {
    @Environment(\.dismiss) private var dismiss

    let categoria: Categoria

    @State private var modulo: ModuloCategoria?
    @State private var categoriaDaEliminare: Categoria?

    /// Vero quando la categoria è stata eliminata (anche insieme a una categoria superiore).
    private var eliminata: Bool {
        categoria.isDeleted || categoria.modelContext == nil
    }

    var body: some View {
        Group {
            if eliminata {
                ContentUnavailableView("Categoria eliminata", systemImage: "folder")
            } else {
                contenuto
            }
        }
        .onChange(of: eliminata) {
            if eliminata { dismiss() }
        }
    }

    private var contenuto: some View {
        let prodotti = categoria.prodottiCompresi
        return Form {
            Section {
                if let genitore = categoria.genitore {
                    LabeledContent("Dentro") {
                        Text(genitore.percorsoTestuale)
                    }
                }
                LabeledContent("Emoji") {
                    if let icona = categoria.icona {
                        Text(icona)
                    } else if let ereditata = categoria.iconaEffettiva {
                        Text("\(ereditata) (dalla categoria superiore)")
                    } else {
                        Text("Nessuna")
                    }
                }
            }

            if categoria.livello < Categoria.livelliMassimi {
                Section {
                    ForEach(categoria.sottocategorieOrdinate) { sottocategoria in
                        RigaNavigabile(valore: sottocategoria) {
                            RigaCategoriaView(categoria: sottocategoria)
                        }
                    }
                    Button("Aggiungi sottocategoria", systemImage: "plus.circle") {
                        modulo = .nuova(genitore: categoria)
                    }
                } header: {
                    Text("Sottocategorie: \(categoria.sottocategorie?.count ?? 0)")
                }
            }

            Section {
                ForEach(prodotti) { prodotto in
                    RigaNavigabile(valore: prodotto) {
                        rigaProdotto(prodotto)
                    }
                }
            } header: {
                Text("Prodotti: \(prodotti.count)")
            } footer: {
                if prodotti.isEmpty {
                    Text("Per classificare un prodotto scegli questa categoria nella sua scheda.")
                }
            }

            Section {
                Button("Elimina categoria", systemImage: "trash", role: .destructive) {
                    categoriaDaEliminare = categoria
                }
                .tint(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(categoria.nome)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifica") { modulo = .modifica(categoria) }
            }
        }
        .moduloCategoria($modulo, dispensa: categoria.dispensa)
        .eliminazioneCategoria($categoriaDaEliminare)
    }

    /// Nome e marca del prodotto; se sta in una sottocategoria, anche il suo nome.
    private func rigaProdotto(_ prodotto: Prodotto) -> some View {
        HStack {
            IconaProdottoView(icona: prodotto.iconaEffettiva, miniatura: prodotto.miniatura)
            VStack(alignment: .leading) {
                Text(prodotto.nomeConMarca)
                    .foregroundStyle(.primary)
                if let sua = prodotto.categoria, sua !== categoria {
                    Text(sua.nome)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    let categoria = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Categoria>()).first { $0.genitore == nil }!
    PilaDiNavigazione {
        DettaglioCategoriaView(categoria: categoria)
    }
    .modelContainer(.anteprima)
}
