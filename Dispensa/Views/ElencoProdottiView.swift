//
//  ElencoProdottiView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Catalogo dei prodotti di una dispensa diviso per categoria, con ricerca, filtri e ordinamento.
struct ElencoProdottiView: View {
    @Environment(\.apriNellaPila) private var apri
    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var stato: StatoProdotti
    @State private var mostraNuovoProdotto = false
    @State private var prodottoInModifica: Prodotto?
    @State private var prodottoDaEliminare: Prodotto?

    init(dispensa: Dispensa) {
        self.dispensa = dispensa
        // L'elenco si apre con la vista predefinita, se c'è.
        _stato = State(initialValue: StatoProdotti.prodotti.conPredefinita(in: dispensa))
    }

    var body: some View {
        // Ricerca e raggruppamento in Services/RicercaProdotti.swift, filtri in FiltriProdotti.swift,
        // ordine in OrdinamentoElenchi.swift.
        let gruppi = dispensa.gruppiDiProdotti(cercando: ricerca, filtro: stato.filtro, ordine: stato.ordine)
        List {
            if stato.mostraRiga, !gruppi.isEmpty {
                RigaFiltriAttivi(stato: $stato, dispensa: dispensa)
            }
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
        .menuVista($stato, dispensa: dispensa) {
            FiltriProdottiView(dispensa: dispensa, filtro: $stato.filtro)
        }
        .searchable(text: $ricerca, prompt: Text("Nome, marca, categoria, #etichetta o codice"))
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
                if stato.filtro.vuoto || !ricerca.trimmingCharacters(in: .whitespaces).isEmpty {
                    ContentUnavailableView.search(text: ricerca)
                } else {
                    NessunRisultatoConFiltri(titolo: "Nessun prodotto con questi filtri", stato: $stato, dispensa: dispensa)
                }
            }
        }
        .toolbar {
#if os(macOS)
            ToolbarItem {
                pulsanteCategorie
            }
            ToolbarItem {
                pulsanteEtichette
            }
#else
            // Su iPhone la barra non ha posto per tutti i pulsanti: "Filtri" e "+" finirebbero in "Altro".
            ToolbarItem {
                Menu("Categorie ed etichette", systemImage: "list.bullet.indent") {
                    pulsanteCategorie
                    pulsanteEtichette
                }
            }
#endif
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

    private var pulsanteCategorie: some View {
        Button("Categorie", systemImage: "list.bullet.indent") { apri?(ElencoCategorie(dispensa: dispensa)) }
    }

    private var pulsanteEtichette: some View {
        Button("Etichette", systemImage: "number") { apri?(ElencoEtichette(dispensa: dispensa)) }
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
        let presenti = prodotto.numeroArticoliPresenti
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
                    let etichette = prodotto.etichetteOrdinate
                    if !etichette.isEmpty {
                        GettoniEtichetteView(etichette: etichette)
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
