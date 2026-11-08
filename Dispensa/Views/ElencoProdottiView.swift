//
//  ElencoProdottiView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Catalogo dei prodotti di una dispensa, con ricerca.
struct ElencoProdottiView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var mostraNuovoProdotto = false
    @State private var prodottoInModifica: Prodotto?
    @State private var prodottoDaEliminare: Prodotto?
    @State private var errore: ErroreGestioneArticoli?

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
        NavigationStack {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
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
            .confirmationDialog(
                "Eliminare il prodotto?",
                isPresented: Binding(
                    get: { prodottoDaEliminare != nil },
                    set: { if !$0 { prodottoDaEliminare = nil } }
                ),
                titleVisibility: .visible,
                presenting: prodottoDaEliminare
            ) { prodotto in
                Button("Elimina", role: .destructive) { elimina(prodotto) }
            } message: { prodotto in
                Text("Articoli di «\(prodotto.nome)» nello storico: \(prodotto.articoli?.count ?? 0). Verranno eliminati anche loro.")
            }
            .alert(
                "Impossibile eliminare",
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
        .frame(minWidth: 420, minHeight: 480)
#endif
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

        return Button {
            prodottoInModifica = prodotto
        } label: {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        Button("Elimina", systemImage: "trash", role: .destructive) {
            let articoli = prodotto.articoli ?? []
            if articoli.contains(where: { $0.stato == .attivo }) {
                errore = .prodottoConArticoliPresenti
            } else if articoli.isEmpty {
                elimina(prodotto)
            } else {
                prodottoDaEliminare = prodotto
            }
        }
    }

    private func elimina(_ prodotto: Prodotto) {
        do {
            try modelContext.eliminaProdotto(prodotto)
        } catch let errore as ErroreGestioneArticoli {
            self.errore = errore
        } catch {
            assertionFailure("Errore inatteso: \(error)")
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    ElencoProdottiView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
