//
//  Dispensa.swift
//  Dispensa
//

import Foundation
import SwiftData

/// L'insieme delle strutture di una casa. Tutti gli altri dati appartengono a una Dispensa,
/// che in futuro sarà l'oggetto condiviso tra più persone.
@Model
final class Dispensa {
    var id: UUID = UUID()
    var nome: String = ""
    var dataCreazione: Date = Date.now
    /// Se `false`, gli articoli consumati o buttati vengono eliminati invece di andare nello storico.
    var storicoAbilitato: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \Ubicazione.dispensa)
    var ubicazioni: [Ubicazione]? = []

    @Relationship(deleteRule: .cascade, inverse: \Struttura.dispensa)
    var strutture: [Struttura]? = []

    @Relationship(deleteRule: .cascade, inverse: \Prodotto.dispensa)
    var prodotti: [Prodotto]? = []

    @Relationship(deleteRule: .cascade, inverse: \Articolo.dispensa)
    var articoli: [Articolo]? = []

    @Relationship(deleteRule: .cascade, inverse: \Categoria.dispensa)
    var categorie: [Categoria]? = []

    @Relationship(deleteRule: .cascade, inverse: \Etichetta.dispensa)
    var etichette: [Etichetta]? = []

    /// Articoli consumati o buttati, dal più recente.
    var articoliNelloStorico: [Articolo] {
        (articoli ?? [])
            .filter { $0.stato != .attivo }
            .sorted { ($0.dataUscita ?? .distantPast) > ($1.dataUscita ?? .distantPast) }
    }

    init(nome: String) {
        self.nome = nome
    }
}
