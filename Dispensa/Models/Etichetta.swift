//
//  Etichetta.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Categoria o hashtag assegnabile ai prodotti.
@Model
final class Etichetta {
    var id: UUID = UUID()
    var nome: String = ""
    var tipoRaw: String = TipoEtichetta.categoria.rawValue
    var coloreRaw: String?

    var dispensa: Dispensa?
    var prodotti: [Prodotto]? = []

    var tipo: TipoEtichetta {
        get { TipoEtichetta(rawValue: tipoRaw) ?? .categoria }
        set { tipoRaw = newValue.rawValue }
    }

    init(nome: String, tipo: TipoEtichetta) {
        self.nome = nome
        self.tipoRaw = tipo.rawValue
    }
}
