//
//  Ubicazione.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Dove si trova una struttura: cucina, cantina, salone, …
@Model
final class Ubicazione {
    var id: UUID = UUID()
    var nome: String = ""

    var dispensa: Dispensa?

    /// Eliminando l'ubicazione, le strutture restano (senza ubicazione).
    @Relationship(deleteRule: .nullify, inverse: \Struttura.ubicazione)
    var strutture: [Struttura]? = []

    init(nome: String) {
        self.nome = nome
    }
}
