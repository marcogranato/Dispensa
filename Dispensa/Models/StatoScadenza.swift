//
//  StatoScadenza.swift
//  Dispensa
//

import Foundation

/// Situazione di un articolo rispetto alla sua data di scadenza. Non viene salvato: si calcola.
enum StatoScadenza: Equatable {
    case senzaScadenza
    case valido
    /// Scade oggi o entro i giorni di preavviso.
    case inScadenza
    /// La data di scadenza è passata.
    case scaduto

    /// Giorni di preavviso per considerare un articolo "in scadenza".
    /// Diventerà un'impostazione con le notifiche (fase 6).
    static let giorniPreavviso = 3
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
