//
//  Unita.swift
//  Dispensa
//

import Foundation

/// Unità di misura della quantità di una parte di un articolo.
enum Unita: String, CaseIterable, Identifiable {
    case grammi
    case chilogrammi
    case millilitri
    case litri
    case pezzi

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .grammi: "Grammi"
        case .chilogrammi: "Chilogrammi"
        case .millilitri: "Millilitri"
        case .litri: "Litri"
        case .pezzi: "Pezzi"
        }
    }

    var simbolo: LocalizedStringResource {
        switch self {
        case .grammi: "g"
        case .chilogrammi: "kg"
        case .millilitri: "ml"
        case .litri: "l"
        case .pezzi: "pz"
        }
    }
}
