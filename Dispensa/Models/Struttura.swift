//
//  Struttura.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Un frigorifero, un congelatore, uno scaffale, … che contiene articoli.
@Model
final class Struttura {
    var id: UUID = UUID()
    var nome: String = ""
    var tipoRaw: String = TipoStruttura.dispensa.rawValue
    /// Nome libero della tipologia, usato quando `tipo` è `.altro`.
    var tipoPersonalizzato: String?
    var numeroRipiani: Int?
    var numeroCassetti: Int?
    var note: String?
    @Attribute(.externalStorage) var immagine: Data?
    var dataCreazione: Date = Date.now

    var dispensa: Dispensa?
    var ubicazione: Ubicazione?

    /// Eliminando la struttura, gli articoli restano (senza struttura): così lo storico non si perde.
    @Relationship(deleteRule: .nullify, inverse: \Articolo.struttura)
    var articoli: [Articolo]? = []

    var tipo: TipoStruttura {
        get { TipoStruttura(rawValue: tipoRaw) ?? .altro }
        set { tipoRaw = newValue.rawValue }
    }

    /// Nome da mostrare per la tipologia: quello personalizzato se il tipo è "altro" e il nome è indicato.
    var nomeTipo: String {
        if tipo == .altro, let tipoPersonalizzato, !tipoPersonalizzato.isEmpty {
            return tipoPersonalizzato
        }
        return String(localized: tipo.nomeLocalizzato)
    }

    var articoliAttivi: [Articolo] {
        (articoli ?? []).filter { $0.stato == .attivo }
    }

    init(nome: String, tipo: TipoStruttura) {
        self.nome = nome
        self.tipoRaw = tipo.rawValue
    }
}
