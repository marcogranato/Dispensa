//
//  ColoreEtichetta.swift
//  Dispensa
//

import Foundation

/// Colore facoltativo di un'etichetta, da una tavolozza fissa (salvato come testo in `Etichetta.coloreRaw`).
enum ColoreEtichetta: String, CaseIterable, Identifiable {
    case rosso
    case arancione
    case giallo
    case verde
    case menta
    case azzurro
    case blu
    case viola
    case rosa
    case marrone
    case grigio

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .rosso: "Rosso"
        case .arancione: "Arancione"
        case .giallo: "Giallo"
        case .verde: "Verde"
        case .menta: "Menta"
        case .azzurro: "Azzurro"
        case .blu: "Blu"
        case .viola: "Viola"
        case .rosa: "Rosa"
        case .marrone: "Marrone"
        case .grigio: "Grigio"
        }
    }
}
