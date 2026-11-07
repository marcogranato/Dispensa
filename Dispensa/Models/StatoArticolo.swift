//
//  StatoArticolo.swift
//  Dispensa
//

import Foundation

/// Stato di un articolo: presente in dispensa oppure uscito (nello storico).
enum StatoArticolo: String, CaseIterable, Identifiable {
    case attivo
    case consumato
    case buttato

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .attivo: "In dispensa"
        case .consumato: "Consumato"
        case .buttato: "Buttato"
        }
    }
}
