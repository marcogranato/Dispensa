//
//  TabellaArticoliView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Le colonne della tabella degli articoli (scheda Articoli e scheda della struttura).
enum ColonnaArticoli: String, ColonnaTabella {
    case nome, marca, struttura, parti, quantita, scadenza, categoria, etichette, inserimento, produzione, codice

    var id: Self { self }

    var titolo: LocalizedStringResource {
        switch self {
        case .nome: "Nome"
        case .marca: "Marca"
        case .struttura: "Struttura"
        case .parti: "Parti"
        case .quantita: "Quantità"
        case .scadenza: "Scadenza"
        case .categoria: "Categoria"
        case .etichette: "Etichette"
        case .inserimento: "Inserimento"
        case .produzione: "Produzione"
        case .codice: "Codice"
        }
    }

    var visibileAllInizio: Bool {
        switch self {
        case .nome, .marca, .struttura, .parti, .quantita, .scadenza: true
        case .categoria, .etichette, .inserimento, .produzione, .codice: false
        }
    }

    var fissa: Bool { self == .nome }

    /// Le colonne di un elenco: nella scheda della struttura manca la struttura.
    static func disponibili(per tipo: TipoElenco) -> [ColonnaArticoli] {
        tipo == .struttura ? allCases.filter { $0 != .struttura } : allCases
    }
}

/// Articoli presenti in tabella (iPad e Mac). Cliccando un'intestazione si cambia l'ordine dell'elenco;
/// doppio clic (Mac) o tocco (iPad) apre il dettaglio; il menu contestuale ha le azioni sull'articolo.
struct TabellaArticoliView: View {
    @Environment(\.apriNellaPila) private var apri

    let articoli: [Articolo]
    let tipo: TipoElenco
    @Binding var ordine: OrdineArticoli
    @Binding var azione: AzioneArticolo?
    @Binding var daEliminare: Articolo?

    @ColonneSalvate private var colonne: TableColumnCustomization<Articolo>
    @State private var selezione = Set<Articolo.ID>()

    init(
        articoli: [Articolo],
        tipo: TipoElenco,
        ordine: Binding<OrdineArticoli>,
        azione: Binding<AzioneArticolo?>,
        daEliminare: Binding<Articolo?>
    ) {
        self.articoli = articoli
        self.tipo = tipo
        _ordine = ordine
        _azione = azione
        _daEliminare = daEliminare
        _colonne = ColonneSalvate(tipo)
    }

    private var ordinamento: Binding<[ComparatoreArticoli]> {
        Binding(
            get: { [ComparatoreArticoli(ordine)] },
            set: { if let primo = $0.first { ordine = primo.ordine } }
        )
    }

    var body: some View {
        Table(articoli, selection: $selezione, sortOrder: ordinamento, columnCustomization: $colonne) {
            colonnePrincipali
            colonneAggiuntive
        }
        .contextMenu(forSelectionType: Articolo.ID.self) { ids in
            if let articolo = unico(ids) {
                Button("Apri", systemImage: "info.circle") { apri?(articolo) }
                Divider()
                MenuAzioniArticolo(articolo: articolo, azione: $azione, daEliminare: $daEliminare)
            }
        } primaryAction: { ids in
            if let articolo = unico(ids) { apri?(articolo) }
        }
    }

    private func unico(_ ids: Set<Articolo.ID>) -> Articolo? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return articoli.first { $0.id == id }
    }

    @TableColumnBuilder<Articolo, ComparatoreArticoli>
    private var colonnePrincipali: some TableColumnContent<Articolo, ComparatoreArticoli> {
        TableColumn(Text(ColonnaArticoli.nome.titolo), sortUsing: ComparatoreArticoli(.nome)) { articolo in
            HStack {
                IconaProdottoView(icona: articolo.prodotto?.iconaEffettiva)
                Text(articolo.nomeVisualizzato)
            }
        }
        .width(min: 140, ideal: 220)
        .customizationID(ColonnaArticoli.nome.rawValue)
        .disabledCustomizationBehavior(.visibility)

        TableColumn(Text(ColonnaArticoli.marca.titolo)) { articolo in
            Text(articolo.prodotto?.marca ?? "")
        }
        .width(min: 60, ideal: 110)
        .configurata(ColonnaArticoli.marca)

        if tipo != .struttura {
            TableColumn(Text(ColonnaArticoli.struttura.titolo), sortUsing: ComparatoreArticoli(.struttura)) { articolo in
                if let struttura = articolo.struttura {
                    Label(struttura.nome, systemImage: struttura.tipo.simbolo)
                }
            }
            .width(min: 80, ideal: 130)
            .configurata(ColonnaArticoli.struttura)
        }

        TableColumn(Text(ColonnaArticoli.parti.titolo)) { articolo in
            if articolo.partiTotali > 1 {
                Text("\(articolo.partiRimaste) di \(articolo.partiTotali)")
            } else {
                Text(articolo.partiRimaste, format: .number)
            }
        }
        .width(min: 40, ideal: 60)
        .configurata(ColonnaArticoli.parti)

        TableColumn(Text(ColonnaArticoli.quantita.titolo)) { articolo in
            Text(Formattazione.quantita(articolo.quantitaPerParte, unita: articolo.unita) ?? "")
        }
        .width(min: 50, ideal: 80)
        .configurata(ColonnaArticoli.quantita)

        TableColumn(Text(ColonnaArticoli.scadenza.titolo), sortUsing: ComparatoreArticoli(.scadenza)) { articolo in
            if let data = articolo.dataScadenza {
                EtichettaScadenzaView(data: data, stato: articolo.statoScadenza())
            }
        }
        .width(min: 90, ideal: 120)
        .configurata(ColonnaArticoli.scadenza)
    }

    @TableColumnBuilder<Articolo, ComparatoreArticoli>
    private var colonneAggiuntive: some TableColumnContent<Articolo, ComparatoreArticoli> {
        TableColumn(Text(ColonnaArticoli.categoria.titolo)) { articolo in
            Text(articolo.prodotto?.categoria?.percorsoTestuale ?? "")
        }
        .width(min: 80, ideal: 160)
        .configurata(ColonnaArticoli.categoria)

        TableColumn(Text(ColonnaArticoli.etichette.titolo)) { articolo in
            EtichetteInRiga(etichette: articolo.prodotto?.etichetteOrdinate ?? [])
        }
        .width(min: 60, ideal: 140)
        .configurata(ColonnaArticoli.etichette)

        TableColumn(Text(ColonnaArticoli.inserimento.titolo), sortUsing: ComparatoreArticoli(.inserimento)) { articolo in
            TestoData(data: articolo.dataInserimento)
        }
        .width(min: 80, ideal: 110)
        .configurata(ColonnaArticoli.inserimento)

        TableColumn(Text(ColonnaArticoli.produzione.titolo)) { articolo in
            TestoData(data: articolo.dataProduzione)
        }
        .width(min: 80, ideal: 110)
        .configurata(ColonnaArticoli.produzione)

        TableColumn(Text(ColonnaArticoli.codice.titolo)) { articolo in
            Text(articolo.prodotto?.codiceBarre ?? "")
                .monospacedDigit()
        }
        .width(min: 80, ideal: 120)
        .configurata(ColonnaArticoli.codice)
    }
}

extension TableColumnContent {
    /// Identificativo e visibilità iniziale di una colonna configurabile.
    func configurata<Colonna: ColonnaTabella>(_ colonna: Colonna) -> some TableColumnContent<TableRowValue, TableColumnSortComparator> {
        customizationID(colonna.rawValue)
            .defaultVisibility(colonna.visibilitaIniziale)
    }
}

/// Una data facoltativa in una cella di tabella (es. "12 mar 2026").
struct TestoData: View {
    let data: Date?

    var body: some View {
        if let data {
            Text(data.formatted(date: .abbreviated, time: .omitted))
        }
    }
}

/// Le etichette in una cella di tabella, una dopo l'altra sulla stessa riga.
struct EtichetteInRiga: View {
    let etichette: [Etichetta]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(etichette) { etichetta in
                GettoneEtichettaView(etichetta)
            }
        }
        .lineLimit(1)
    }
}
