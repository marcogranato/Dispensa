//
//  Categoria.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Un nodo dell'albero delle categorie dei prodotti, es. "Pasta e riso ▸ Pasta secca ▸ Pasta di semola".
/// Un prodotto si collega al nodo più preciso che si conosce; il percorso completo si ricava dai genitori.
@Model
final class Categoria {
    /// Livelli massimi dell'albero: categoria, sottocategoria, tipologia.
    static let livelliMassimi = 3

    var id: UUID = UUID()
    var nome: String = ""
    /// Emoji facoltativa; se manca si usa quella del primo genitore che ne ha una.
    var icona: String?
    var dataCreazione: Date = Date.now

    var dispensa: Dispensa?

    /// `nil` per una categoria principale.
    var genitore: Categoria?

    @Relationship(deleteRule: .nullify, inverse: \Categoria.genitore)
    var sottocategorie: [Categoria]? = []

    @Relationship(deleteRule: .nullify, inverse: \Prodotto.categoria)
    var prodotti: [Prodotto]? = []

    init(nome: String) {
        self.nome = nome
    }

    /// Dalla categoria principale fino a questa (compresa).
    var percorso: [Categoria] {
        var risultato: [Categoria] = [self]
        var visitati: Set<UUID> = [id]
        var corrente = genitore
        // `visitati` protegge da eventuali cicli in dati corrotti.
        while let nodo = corrente, visitati.insert(nodo.id).inserted {
            risultato.insert(nodo, at: 0)
            corrente = nodo.genitore
        }
        return risultato
    }

    /// Es. "Pasta e riso ▸ Pasta secca ▸ Pasta di semola".
    var percorsoTestuale: String {
        percorso.map(\.nome).joined(separator: " ▸ ")
    }

    /// 1 per una categoria principale, 2 per una sottocategoria, 3 per una tipologia.
    var livello: Int { percorso.count }

    /// L'emoji di questa categoria o, se manca, del genitore più vicino che ne ha una.
    var iconaEffettiva: String? {
        percorso.reversed().lazy.compactMap(\.iconaValida).first
    }

    /// Sottocategorie dirette, in ordine alfabetico.
    var sottocategorieOrdinate: [Categoria] {
        (sottocategorie ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    /// Tutte le sottocategorie, a qualunque livello sotto questa (esclusa).
    var discendenti: [Categoria] {
        var risultato: [Categoria] = []
        var visitati: Set<UUID> = [id]
        var daVisitare = sottocategorie ?? []
        while let nodo = daVisitare.popLast() {
            guard visitati.insert(nodo.id).inserted else { continue }
            risultato.append(nodo)
            daVisitare.append(contentsOf: nodo.sottocategorie ?? [])
        }
        return risultato
    }

    private var iconaValida: String? {
        guard let icona, !icona.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return icona
    }
}
