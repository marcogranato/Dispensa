//
//  ElencoProdottiView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Catalogo dei prodotti di una dispensa, con ricerca.
struct ElencoProdottiView: View {
    @Environment(\.apriNellaPila) private var apri
    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var mostraNuovoProdotto = false
    @State private var prodottoInModifica: Prodotto?
    @State private var prodottoDaEliminare: Prodotto?

    var body: some View {
        // Ricerca, raggruppamento e ordine sono in Services/RicercaProdotti.swift.
        let gruppi = dispensa.gruppiDiProdotti(cercando: ricerca)
        List {
            ForEach(gruppi) { gruppo in
                Section {
                    ForEach(gruppo.prodotti) { prodotto in
                        riga(prodotto)
                    }
                } header: {
                    intestazione(gruppo.categoria)
                }
            }
        }
        .navigationTitle("Prodotti")
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria o codice"))
        .overlay {
            if dispensa.prodotti?.isEmpty ?? true {
                ContentUnavailableView {
                    Label("Nessun prodotto", systemImage: "carrot")
                } description: {
                    Text("I prodotti sono le schede riutilizzabili (nome, marca, confezione) degli articoli che metti in dispensa.")
                } actions: {
                    Button("Aggiungi un prodotto") { mostraNuovoProdotto = true }
                        .buttonStyle(.borderedProminent)
                }
            } else if gruppi.isEmpty {
                ContentUnavailableView.search(text: ricerca)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Categorie", systemImage: "list.bullet.indent") { apri?(ElencoCategorie(dispensa: dispensa)) }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Nuovo prodotto", systemImage: "plus") { mostraNuovoProdotto = true }
            }
        }
        .sheet(isPresented: $mostraNuovoProdotto) {
            ProdottoFormView(dispensa: dispensa)
        }
        .sheet(item: $prodottoInModifica) { prodotto in
            ProdottoFormView(dispensa: dispensa, prodotto: prodotto)
        }
        .eliminazioneProdotto($prodottoDaEliminare)
    }

    /// Titolo della sezione: emoji e nome della categoria principale, o "Senza categoria".
    @ViewBuilder
    private func intestazione(_ categoria: Categoria?) -> some View {
        if let categoria {
            HStack(spacing: 6) {
                if let emoji = categoria.iconaEffettiva {
                    Text(emoji)
                        .accessibilityHidden(true)
                }
                Text(categoria.nome)
            }
        } else {
            Text("Senza categoria")
        }
    }

    private func riga(_ prodotto: Prodotto) -> some View {
        let presenti = (prodotto.articoli ?? []).filter { $0.stato == .attivo }.count
        let dettagli = [
            prodotto.marca,
            // La sezione dice già la categoria principale: qui serve solo la parte sotto.
            prodotto.percorsoSottocategoria,
            Formattazione.confezione(
                parti: prodotto.partiPerConfezione,
                quantitaPerParte: prodotto.quantitaPerParte,
                unita: prodotto.unita
            ),
        ].compactMap { $0 }

        // Il click apre la scheda del prodotto; la modifica è nel menu contestuale o nella scheda.
        return RigaNavigabile(valore: prodotto) {
            HStack {
                IconaProdottoView(icona: prodotto.iconaEffettiva)
                VStack(alignment: .leading) {
                    Text(prodotto.nome)
                        .foregroundStyle(.primary)
                    if !dettagli.isEmpty {
                        Text(dettagli.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(presenti, format: .number)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityLabel(Text("Articoli presenti: \(presenti)"))
            }
        }
        .contextMenu {
            pulsanteModifica(prodotto)
            pulsanteElimina(prodotto)
        }
        .swipeActions {
            pulsanteElimina(prodotto)
            pulsanteModifica(prodotto)
        }
    }

    private func pulsanteModifica(_ prodotto: Prodotto) -> some View {
        Button("Modifica", systemImage: "pencil") { prodottoInModifica = prodotto }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ prodotto: Prodotto) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) { prodottoDaEliminare = prodotto }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        ElencoProdottiView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
