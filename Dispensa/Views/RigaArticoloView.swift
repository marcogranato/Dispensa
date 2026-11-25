//
//  RigaArticoloView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Riga di un articolo negli elenchi: a sinistra l'icona, centrata; accanto nome, marca, parti e quantità,
/// scadenza evidenziata e, sotto, la struttura (quando serve), allineata al nome.
struct RigaArticoloView: View {
    let articolo: Articolo
    /// Il nome della struttura, per gli elenchi con articoli di più strutture.
    var struttura: String?

    private var dettagli: String? {
        let parti = articolo.partiTotali > 1
            ? String(localized: "\(articolo.partiRimaste) di \(articolo.partiTotali)")
            : nil
        let quantita = Formattazione.quantita(articolo.quantitaPerParte, unita: articolo.unita)
        // La marca distingue articoli dello stesso prodotto di marche diverse (es. Penne rigate Barilla e De Cecco).
        let testo = [articolo.prodotto?.marca, parti, quantita].compactMap { $0 }.joined(separator: " · ")
        return testo.isEmpty ? nil : testo
    }

    var body: some View {
        HStack(spacing: 12) {
            icona
            VStack(alignment: .leading, spacing: 2) {
                // Prima prova nome, dettagli e scadenza su una riga; se non ci stanno (nome lungo, testo grande)
                // i dettagli vanno sotto il nome.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(articolo.nomeVisualizzato)
                            .lineLimit(1)
                            .fixedSize()
                        if let dettagli {
                            testoDettagli(dettagli)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        Spacer(minLength: 8)
                        scadenza
                            .fixedSize()
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text(articolo.nomeVisualizzato)
                            if let dettagli {
                                testoDettagli(dettagli)
                            }
                        }
                        Spacer()
                        scadenza
                    }
                }
                if let struttura {
                    Text(struttura)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // La linea tra le righe parte dal testo, uguale per tutte le righe.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }

    private var icona: some View {
        IconaProdottoView(icona: articolo.prodotto?.iconaEffettiva, miniatura: articolo.prodotto?.miniatura)
    }

    private func testoDettagli(_ testo: String) -> some View {
        Text(testo)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var scadenza: some View {
        if let data = articolo.dataScadenza {
            EtichettaScadenzaView(data: data, stato: articolo.statoScadenza())
                .font(.caption)
        }
    }
}

/// Data di scadenza colorata, con icona per gli articoli scaduti o in scadenza.
struct EtichettaScadenzaView: View {
    let data: Date
    let stato: StatoScadenza

    var body: some View {
        let testoData = data.formatted(date: .abbreviated, time: .omitted)
        Group {
            switch stato {
            case .scaduto:
                Label(testoData, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel(Text("Scaduto il \(testoData)"))
            case .inScadenza:
                Label(testoData, systemImage: "clock")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(Text("In scadenza il \(testoData)"))
            case .valido, .senzaScadenza:
                Text(testoData)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("Scade il \(testoData)"))
            }
        }
        .labelStyle(.titleAndIcon)
    }
}
