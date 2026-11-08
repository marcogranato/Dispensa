//
//  Formattazione.swift
//  Dispensa
//

import Foundation

/// Testi formattati condivisi tra le viste.
enum Formattazione {
    /// Es. "150 g", "1,5 l"; `nil` se la quantità non è indicata.
    static func quantita(_ valore: Double?, unita: Unita?) -> String? {
        guard let valore else { return nil }
        let numero = valore.formatted(.number.precision(.fractionLength(0...2)))
        guard let unita else { return numero }
        return String(localized: "\(numero) \(String(localized: unita.simbolo))")
    }

    /// Es. "6 × 150 g", "6 parti", "1,5 l"; `nil` se non c'è niente da mostrare.
    static func confezione(parti: Int, quantitaPerParte: Double?, unita: Unita?) -> String? {
        let quantita = quantita(quantitaPerParte, unita: unita)
        switch (parti > 1, quantita) {
        case (true, let quantita?):
            return String(localized: "\(parti) × \(quantita)")
        case (true, nil):
            return String(localized: "\(parti) parti")
        case (false, let quantita?):
            return quantita
        case (false, nil):
            return nil
        }
    }
}
