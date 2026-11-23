//
//  TabellaStoricoView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Le colonne della tabella dello storico.
enum ColonnaStorico: String, ColonnaTabella {
    case nome, esito, uscita, struttura, partiButtate, marca, categoria, scadenza, inserimento, etichette

    var id: Self { self }

    var titolo: LocalizedStringResource {
        switch self {
        case .nome: "Nome"
        case .esito: "Esito"
        case .uscita: "Data di uscita"
        case .struttura: "Struttura"
        case .partiButtate: "Parti buttate"
        case .marca: "Marca"
        case .categoria: "Categoria"
        case .scadenza: "Scadenza"
        case .inserimento: "Inserimento"
        case .etichette: "Etichette"
        }
    }

    var visibileAllInizio: Bool {
        switch self {
        case .nome, .esito, .uscita, .struttura, .partiButtate: true
        case .marca, .categoria, .scadenza, .inserimento, .etichette: false
        }
    }

    var fissa: Bool { self == .nome }
}

/// Lo storico in tabella (iPad e Mac). Come nell'elenco, un clic seleziona (per eliminare più articoli);
/// il menu contestuale rimette in dispensa o elimina.
struct TabellaStoricoView: View {
    let articoli: [Articolo]
    @Binding var ordine: OrdineArticoli
    @Binding var selezione: Set<Articolo.ID>
    let rimetti: (Articolo) -> Void
    let elimina: ([Articolo]) -> Void

    @ColonneSalvate(.storico) private var colonne: TableColumnCustomization<Articolo>

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
            let scelti = articoli.filter { ids.contains($0.id) }
            if scelti.count == 1, let articolo = scelti.first {
                Button("Rimetti in dispensa", systemImage: "arrow.uturn.backward") { rimetti(articolo) }
            }
            if !scelti.isEmpty {
                Button(
                    scelti.count == 1 ? "Elimina dallo storico" : "Elimina selezionati (\(scelti.count))",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    elimina(scelti)
                }
            }
        }
    }

    @TableColumnBuilder<Articolo, ComparatoreArticoli>
    private var colonnePrincipali: some TableColumnContent<Articolo, ComparatoreArticoli> {
        TableColumn(Text(ColonnaStorico.nome.titolo), sortUsing: ComparatoreArticoli(.nome)) { articolo in
            HStack {
                IconaProdottoView(icona: articolo.prodotto?.iconaEffettiva)
                Text(articolo.nomeVisualizzato)
            }
        }
        .width(min: 140, ideal: 220)
        .customizationID(ColonnaStorico.nome.rawValue)
        .disabledCustomizationBehavior(.visibility)

        TableColumn(Text(ColonnaStorico.esito.titolo)) { articolo in
            Label {
                Text(articolo.descrizioneEsito)
            } icon: {
                Image(systemName: articolo.simboloEsito)
                    .foregroundStyle(articolo.coloreEsito)
            }
        }
        .width(min: 90, ideal: 150)
        .configurata(ColonnaStorico.esito)

        TableColumn(Text(ColonnaStorico.uscita.titolo), sortUsing: ComparatoreArticoli(.uscita)) { articolo in
            TestoData(data: articolo.dataUscita)
        }
        .width(min: 80, ideal: 110)
        .configurata(ColonnaStorico.uscita)

        TableColumn(Text(ColonnaStorico.struttura.titolo)) { articolo in
            if let struttura = articolo.struttura {
                Label(struttura.nome, systemImage: struttura.tipo.simbolo)
            }
        }
        .width(min: 80, ideal: 130)
        .configurata(ColonnaStorico.struttura)

        TableColumn(Text(ColonnaStorico.partiButtate.titolo)) { articolo in
            if articolo.partiButtate > 0 {
                Text("\(articolo.partiButtate) di \(articolo.partiTotali)")
            }
        }
        .width(min: 50, ideal: 90)
        .configurata(ColonnaStorico.partiButtate)
    }

    @TableColumnBuilder<Articolo, ComparatoreArticoli>
    private var colonneAggiuntive: some TableColumnContent<Articolo, ComparatoreArticoli> {
        TableColumn(Text(ColonnaStorico.marca.titolo)) { articolo in
            Text(articolo.prodotto?.marca ?? "")
        }
        .width(min: 60, ideal: 110)
        .configurata(ColonnaStorico.marca)

        TableColumn(Text(ColonnaStorico.categoria.titolo)) { articolo in
            Text(articolo.prodotto?.categoria?.percorsoTestuale ?? "")
        }
        .width(min: 80, ideal: 160)
        .configurata(ColonnaStorico.categoria)

        TableColumn(Text(ColonnaStorico.scadenza.titolo), sortUsing: ComparatoreArticoli(.scadenza)) { articolo in
            TestoData(data: articolo.dataScadenza)
        }
        .width(min: 80, ideal: 110)
        .configurata(ColonnaStorico.scadenza)

        TableColumn(Text(ColonnaStorico.inserimento.titolo)) { articolo in
            TestoData(data: articolo.dataInserimento)
        }
        .width(min: 80, ideal: 110)
        .configurata(ColonnaStorico.inserimento)

        TableColumn(Text(ColonnaStorico.etichette.titolo)) { articolo in
            EtichetteInRiga(etichette: articolo.prodotto?.etichetteOrdinate ?? [])
        }
        .width(min: 60, ideal: 140)
        .configurata(ColonnaStorico.etichette)
    }
}
