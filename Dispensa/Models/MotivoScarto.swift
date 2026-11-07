//
//  MotivoScarto.swift
//  Dispensa
//

import Foundation

/// Motivo per cui un articolo è stato buttato.
enum MotivoScarto: String, CaseIterable, Identifiable {
    case scaduto
    case avariato
    case altro

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .scaduto: "Scaduto"
        case .avariato: "Avariato"
        case .altro: "Altro"
        }
    }
}
