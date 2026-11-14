//
//  TipoParte.swift
//  Dispensa
//

import Foundation

/// Che cosa è ogni parte di una confezione (es. i 4 pacchetti di una scatola di biscotti).
/// Salvato in `Prodotto.tipoParteRaw` come stringa.
enum TipoParte: String, CaseIterable, Identifiable {
    case confezione
    case pacchetto
    case bustina
    case bottiglia
    case lattina
    case vasetto
    case scatoletta
    case brick
    case vaschetta
    case pezzo

    var id: Self { self }

    /// Nome per i menu, es. "Pacchetto".
    var nomeSingolare: LocalizedStringResource {
        switch self {
        case .confezione: "Confezione"
        case .pacchetto: "Pacchetto"
        case .bustina: "Bustina"
        case .bottiglia: "Bottiglia"
        case .lattina: "Lattina"
        case .vasetto: "Vasetto"
        case .scatoletta: "Scatoletta"
        case .brick: "Brick"
        case .vaschetta: "Vaschetta"
        case .pezzo: "Pezzo"
        }
    }

    /// Plurale minuscolo per i conteggi, es. "4 pacchetti da 100 g".
    var nomePlurale: LocalizedStringResource {
        switch self {
        case .confezione: "confezioni"
        case .pacchetto: "pacchetti"
        case .bustina: "bustine"
        case .bottiglia: "bottiglie"
        case .lattina: "lattine"
        case .vasetto: "vasetti"
        case .scatoletta: "scatolette"
        case .brick: "brick"
        case .vaschetta: "vaschette"
        case .pezzo: "pezzi"
        }
    }
}
