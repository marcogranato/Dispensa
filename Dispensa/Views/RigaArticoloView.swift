//
//  RigaArticoloView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Riga di un articolo negli elenchi: nome, parti e quantità, scadenza evidenziata.
struct RigaArticoloView: View {
    let articolo: Articolo

    private var dettagli: String? {
        let parti = articolo.partiTotali > 1
            ? String(localized: "\(articolo.partiRimaste) di \(articolo.partiTotali)")
            : nil
        let quantita = Formattazione.quantita(articolo.quantitaPerParte, unita: articolo.unita)
        let testo = [parti, quantita].compactMap { $0 }.joined(separator: " · ")
        return testo.isEmpty ? nil : testo
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(articolo.nomeVisualizzato)
                if let dettagli {
                    Text(dettagli)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let scadenza = articolo.dataScadenza {
                EtichettaScadenzaView(data: scadenza, stato: articolo.statoScadenza())
                    .font(.caption)
            }
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
