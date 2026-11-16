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

    private var prodotti: [Prodotto] {
        let testo = ricerca.trimmingCharacters(in: .whitespacesAndNewlines)
        return (dispensa.prodotti ?? [])
            .filter { prodotto in
                testo.isEmpty
                    || prodotto.nome.localizedStandardContains(testo)
                    || (prodotto.marca?.localizedStandardContains(testo) ?? false)
                    || prodotto.codiceBarre == testo
            }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        List {
            ForEach(prodotti) { prodotto in
                riga(prodotto)
            }
        }
        .navigationTitle("Prodotti")
        .searchable(text: $ricerca, prompt: Text("Nome, marca o codice"))
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
            } else if prodotti.isEmpty {
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

    private func riga(_ prodotto: Prodotto) -> some View {
        let presenti = (prodotto.articoli ?? []).filter { $0.stato == .attivo }.count
        let dettagli = [
            prodotto.marca,
            Formattazione.confezione(
                parti: prodotto.partiPerConfezione,
                quantitaPerParte: prodotto.quantitaPerParte,
                unita: prodotto.unita
            ),
        ].compactMap { $0 }

        // Il click apre la scheda del prodotto; la modifica è nel menu contestuale o nella scheda.
        return RigaNavigabile(valore: prodotto) {
            HStack {
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
