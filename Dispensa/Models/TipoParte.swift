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

    var nomePlurale: LocalizedStringResource {
        switch self {
        case .confezione: "Confezioni"
        case .pacchetto: "Pacchetti"
        case .bustina: "Bustine"
        case .bottiglia: "Bottiglie"
        case .lattina: "Lattine"
        case .vasetto: "Vasetti"
        case .scatoletta: "Scatolette"
        // Chiave distinta dal singolare: in italiano è uguale, in altre lingue no.
        case .brick: LocalizedStringResource("tipoParte.brick.plurale", defaultValue: "Brick")
        case .vaschetta: "Vaschette"
        case .pezzo: "Pezzi"
        }
    }
}
