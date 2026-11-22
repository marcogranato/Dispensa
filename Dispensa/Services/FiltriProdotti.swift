//
//  FiltriProdotti.swift
//  Dispensa
//

import Foundation

/// Se un prodotto ha articoli in dispensa oppure no (es. per trovare quelli finiti, da ricomprare).
enum PresenzaProdotto: String, CaseIterable, Identifiable, Hashable {
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
struct FiltroProdotti: FiltroElenco {
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

    /// I prodotti che passano i filtri, nello stesso ordine.
    func applica(_ prodotti: [Prodotto]) -> [Prodotto] {
        guard !vuoto else { return prodotti }
        return prodotti.filter(include)
    }
}
