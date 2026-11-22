//
//  FiltriProdotti.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Se un prodotto ha articoli in dispensa oppure no (es. per trovare quelli finiti, da ricomprare).
enum PresenzaProdotto: String, CaseIterable, Identifiable, Hashable, Codable {
    case conArticoli, senzaArticoli

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .conArticoli: "Con articoli"
        case .senzaArticoli: "Senza articoli"
        }
    }

    var simbolo: String {
        switch self {
        case .conArticoli: "shippingbox.fill"
        case .senzaArticoli: "shippingbox"
        }
    }
}

/// Filtri sulla scheda Prodotti, con le stesse regole di `FiltroArticoli`:
/// dentro un gruppo basta una delle scelte, tra gruppi diversi devono valere tutti.
struct FiltroProdotti: FiltroSalvabile {
    /// Una categoria comprende le sue sottocategorie.
    var categorie: Set<UUID> = []
    var etichette: Set<UUID> = []
    var presenze: Set<PresenzaProdotto> = []

    var numeroAttivi: Int {
        [!categorie.isEmpty, !etichette.isEmpty, !presenze.isEmpty].filter { $0 }.count
    }

    func include(_ prodotto: Prodotto) -> Bool {
        if !categorie.isEmpty, !prodotto.appartiene(aUnaDi: categorie) { return false }
        if !etichette.isEmpty, !prodotto.haUnaDelle(etichette: etichette) { return false }
        if !presenze.isEmpty {
            let presenza: PresenzaProdotto = prodotto.numeroArticoliPresenti > 0 ? .conArticoli : .senzaArticoli
            if !presenze.contains(presenza) { return false }
        }
        return true
    }

    /// Toglie categorie ed etichette che non esistono più (es. in una vista salvata).
    func ripulito(per dispensa: Dispensa) -> FiltroProdotti {
        var copia = self
        copia.categorie.formIntersection(dispensa.categorie?.filter { !$0.isDeleted }.map(\.id) ?? [])
        copia.etichette.formIntersection(dispensa.etichette?.filter { !$0.isDeleted }.map(\.id) ?? [])
        return copia
    }

    /// I prodotti che passano i filtri, nello stesso ordine.
    func applica(_ prodotti: [Prodotto]) -> [Prodotto] {
        guard !vuoto else { return prodotti }
        return prodotti.filter(include)
    }
}

// Nell'estensione, così restano gli inizializzatori automatici (`FiltroProdotti()`, `FiltroProdotti(categorie:)`…).
extension FiltroProdotti {
    /// Lettura tollerante, come per `FiltroArticoli`.
    init(from decoder: Decoder) throws {
        let campi = try decoder.container(keyedBy: CodingKeys.self)
        categorie = campi.leggi(.categorie, altrimenti: [])
        etichette = campi.leggi(.etichette, altrimenti: [])
        presenze = campi.leggi(.presenze, altrimenti: [])
    }
}
