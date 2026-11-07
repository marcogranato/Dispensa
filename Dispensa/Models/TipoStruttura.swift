//
//  TipoStruttura.swift
//  Dispensa
//

import Foundation

/// Tipologia di una struttura (frigorifero, scaffale, …).
/// Salvata in `Struttura.tipoRaw` come stringa.
enum TipoStruttura: String, CaseIterable, Identifiable {
    case frigorifero
    case congelatore
    case dispensa
    case estraibile
    case scaffale
    case altro

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .frigorifero: "Frigorifero"
        case .congelatore: "Congelatore"
        case .dispensa: "Dispensa"
        case .estraibile: "Estraibile"
        case .scaffale: "Scaffale"
        case .altro: "Altro"
        }
    }

    /// Nome del simbolo SF Symbols usato come icona.
    var simbolo: String {
        switch self {
        case .frigorifero: "refrigerator"
        case .congelatore: "snowflake"
        case .dispensa: "cabinet"
        case .estraibile: "tray.2"
        case .scaffale: "square.stack.3d.up"
        case .altro: "shippingbox"
        }
    }
}
