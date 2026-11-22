//
//  StatoScadenza.swift
//  Dispensa
//

import Foundation

/// Situazione di un articolo rispetto alla sua data di scadenza. Non viene salvato: si calcola.
enum StatoScadenza: String, Hashable, CaseIterable, Identifiable {
    /// La data di scadenza è passata.
    case scaduto
    /// Scade oggi o entro i giorni di preavviso.
    case inScadenza
    case valido
    case senzaScadenza

    /// Giorni di preavviso per considerare un articolo "in scadenza".
    /// Diventerà un'impostazione con le notifiche (fase 6).
    static let giorniPreavviso = 3

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .scaduto: "Scaduti"
        case .inScadenza: "In scadenza"
        case .valido: "Non in scadenza"
        case .senzaScadenza: "Senza scadenza"
        }
    }

    /// Lo stesso simbolo usato accanto alla data nelle righe degli articoli (quando c'è).
    var simbolo: String {
        switch self {
        case .scaduto: "exclamationmark.triangle.fill"
        case .inScadenza: "clock"
        case .valido: "checkmark.circle"
        case .senzaScadenza: "calendar.badge.minus"
        }
    }
}

extension Articolo {
    /// Confronta solo i giorni, non le ore: un articolo che scade oggi è in scadenza, non scaduto.
    func statoScadenza(oggi: Date = .now, calendario: Calendar = .current) -> StatoScadenza {
        guard let dataScadenza else { return .senzaScadenza }
        let giorni = calendario.dateComponents(
            [.day],
            from: calendario.startOfDay(for: oggi),
            to: calendario.startOfDay(for: dataScadenza)
        ).day ?? 0
        if giorni < 0 { return .scaduto }
        if giorni <= StatoScadenza.giorniPreavviso { return .inScadenza }
        return .valido
    }
}
