//
//  TabellaProdottiView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Le colonne della tabella dei prodotti.
enum ColonnaProdotti: String, ColonnaTabella {
    case nome, marca, categoria, confezione, etichette, presenti, creazione, codice, tipoParte

    var id: Self { self }

    var titolo: LocalizedStringResource {
        switch self {
        case .nome: "Nome"
        case .marca: "Marca"
        case .categoria: "Categoria"
        case .confezione: "Confezione"
        case .etichette: "Etichette"
        case .presenti: "Presenti"
        case .creazione: "Data di creazione"
        case .codice: "Codice"
        case .tipoParte: "Tipo di parte"
        }
    }

    var visibileAllInizio: Bool {
        switch self {
        case .nome, .marca, .categoria, .confezione, .etichette, .presenti: true
        case .creazione, .codice, .tipoParte: false
        }
    }

    var fissa: Bool { self == .nome }
}

/// I prodotti in tabella (iPad e Mac), divisi per categoria principale come nell'elenco.
/// Il Mac mostra il titolo di ogni sezione; iPad no, per questo c'è la colonna Categoria.
/// Doppio clic (Mac) o tocco (iPad) apre la scheda; il menu contestuale modifica o elimina.
struct TabellaProdottiView: View {
    @Environment(\.apriNellaPila) private var apri

    let gruppi: [GruppoProdotti]
    @Binding var ordine: OrdineProdotti
    let modifica: (Prodotto) -> Void
    let elimina: (Prodotto) -> Void

    @ColonneSalvate(.prodotti) private var colonne: TableColumnCustomization<Prodotto>
    @State private var selezione = Set<Prodotto.ID>()

    private var ordinamento: Binding<[ComparatoreProdotti]> {
        Binding(
            get: { [ComparatoreProdotti(ordine)] },
            set: { if let primo = $0.first { ordine = primo.ordine } }
        )
    }

    var body: some View {
        Table(of: Prodotto.self, selection: $selezione, sortOrder: ordinamento, columnCustomization: $colonne) {
            colonnePrincipali
            colonneAggiuntive
        } rows: {
            ForEach(gruppi) { gruppo in
                Section {
                    ForEach(gruppo.prodotti) { prodotto in
                        TableRow(prodotto)
                    }
                } header: {
                    IntestazioneCategoria(categoria: gruppo.categoria)
                }
            }
        }
        .contextMenu(forSelectionType: Prodotto.ID.self) { ids in
            if let prodotto = unico(ids) {
                Button("Apri", systemImage: "info.circle") { apri?(prodotto) }
                Divider()
                Button("Modifica", systemImage: "pencil") { modifica(prodotto) }
                Button("Elimina", systemImage: "trash", role: .destructive) { elimina(prodotto) }
            }
        } primaryAction: { ids in
            if let prodotto = unico(ids) { apri?(prodotto) }
        }
    }

    private func unico(_ ids: Set<Prodotto.ID>) -> Prodotto? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return gruppi.lazy.flatMap(\.prodotti).first { $0.id == id }
    }

    @TableColumnBuilder<Prodotto, ComparatoreProdotti>
    private var colonnePrincipali: some TableColumnContent<Prodotto, ComparatoreProdotti> {
        TableColumn(Text(ColonnaProdotti.nome.titolo), sortUsing: ComparatoreProdotti(.nome)) { prodotto in
            HStack {
                IconaProdottoView(icona: prodotto.iconaEffettiva)
                Text(prodotto.nome)
            }
        }
        .width(min: 140, ideal: 220)
        .customizationID(ColonnaProdotti.nome.rawValue)
        .disabledCustomizationBehavior(.visibility)

        TableColumn(Text(ColonnaProdotti.marca.titolo)) { prodotto in
            Text(prodotto.marca ?? "")
        }
        .width(min: 60, ideal: 110)
        .configurata(ColonnaProdotti.marca)

        // Percorso completo: su iPad la tabella non mostra i titoli delle sezioni.
        TableColumn(Text(ColonnaProdotti.categoria.titolo)) { prodotto in
            Text(prodotto.categoria?.percorsoTestuale ?? "")
        }
        .width(min: 80, ideal: 180)
        .configurata(ColonnaProdotti.categoria)

        TableColumn(Text(ColonnaProdotti.confezione.titolo)) { prodotto in
            Text(Formattazione.confezione(
                parti: prodotto.partiPerConfezione,
                quantitaPerParte: prodotto.quantitaPerParte,
                unita: prodotto.unita
            ) ?? "")
        }
        .width(min: 60, ideal: 100)
        .configurata(ColonnaProdotti.confezione)

        TableColumn(Text(ColonnaProdotti.etichette.titolo)) { prodotto in
            EtichetteInRiga(etichette: prodotto.etichetteOrdinate)
        }
        .width(min: 60, ideal: 140)
        .configurata(ColonnaProdotti.etichette)
    }

    @TableColumnBuilder<Prodotto, ComparatoreProdotti>
    private var colonneAggiuntive: some TableColumnContent<Prodotto, ComparatoreProdotti> {
        TableColumn(Text(ColonnaProdotti.presenti.titolo), sortUsing: ComparatoreProdotti(.presenti)) { prodotto in
            let presenti = prodotto.numeroArticoliPresenti
            Text(presenti, format: .number)
                .monospacedDigit()
                .accessibilityLabel(Text("Articoli presenti: \(presenti)"))
        }
        .width(min: 50, ideal: 80)
        .configurata(ColonnaProdotti.presenti)

        TableColumn(Text(ColonnaProdotti.creazione.titolo), sortUsing: ComparatoreProdotti(.creazione)) { prodotto in
            TestoData(data: prodotto.dataCreazione)
        }
        .width(min: 80, ideal: 120)
        .configurata(ColonnaProdotti.creazione)

        TableColumn(Text(ColonnaProdotti.codice.titolo)) { prodotto in
            Text(prodotto.codiceBarre ?? "")
                .monospacedDigit()
        }
        .width(min: 80, ideal: 120)
        .configurata(ColonnaProdotti.codice)

        TableColumn(Text(ColonnaProdotti.tipoParte.titolo)) { prodotto in
            if let tipoParte = prodotto.tipoParte {
                Text(tipoParte.nomeSingolare)
            }
        }
        .width(min: 60, ideal: 100)
        .configurata(ColonnaProdotti.tipoParte)
    }
}

/// Titolo della sezione di una categoria principale: emoji e nome, o "Senza categoria".
struct IntestazioneCategoria: View {
    let categoria: Categoria?

    var body: some View {
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
}
