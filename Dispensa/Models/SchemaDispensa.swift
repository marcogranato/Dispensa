//
//  SchemaDispensa.swift
//  Dispensa
//

import SwiftData

/// Elenco unico dei modelli SwiftData, usato dall'app, dalle anteprime e dai test.
enum SchemaDispensa {
    static let modelli: [any PersistentModel.Type] = [
        Dispensa.self,
        Ubicazione.self,
        Struttura.self,
        Prodotto.self,
        Articolo.self,
        Categoria.self,
        Etichetta.self,
    ]

    static var schema: Schema { Schema(modelli) }
}
