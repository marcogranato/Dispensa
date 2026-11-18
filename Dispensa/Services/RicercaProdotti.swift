//
//  RicercaProdotti.swift
//  Dispensa
//

import Foundation

/// I prodotti di una categoria principale (sottocategorie comprese), o quelli senza categoria.
struct GruppoProdotti: Identifiable {
    /// La categoria principale; `nil` per i prodotti senza categoria.
    let categoria: Categoria?
    let prodotti: [Prodotto]

    var id: String { categoria?.id.uuidString ?? "senza-categoria" }
}

extension Prodotto {
    /// Vero se il testo compare nel nome, nella marca o nel nome di una delle sue categorie
    /// (quella del prodotto o una superiore), oppure è esattamente il codice a barre.
    /// Maiuscole e accenti non contano; un testo vuoto trova tutto.
    func corrisponde(a ricerca: String) -> Bool {
        let testo = ricerca.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !testo.isEmpty else { return true }
        return nome.localizedStandardContains(testo)
            || (marca?.localizedStandardContains(testo) ?? false)
            || codiceBarre == testo
            || (categoria?.percorso.contains { $0.nome.localizedStandardContains(testo) } ?? false)
    }

    /// La categoria principale del prodotto (la radice del suo percorso).
    var categoriaPrincipale: Categoria? {
        categoria?.percorso.first
    }

    /// La parte del percorso sotto la categoria principale (es. "Pasta secca ▸ Pasta di semola");
    /// `nil` se il prodotto sta direttamente in una categoria principale o non ha categoria.
    var percorsoSottocategoria: String? {
        guard let percorso = categoria?.percorso, percorso.count > 1 else { return nil }
        return percorso.dropFirst().map(\.nome).joined(separator: " ▸ ")
    }

    /// Ordine per nome e, a parità di nome, per marca (prima i prodotti senza marca).
    static func ordinePerNomeEMarca(_ a: Prodotto, _ b: Prodotto) -> Bool {
        let perNome = a.nome.localizedStandardCompare(b.nome)
        if perNome != .orderedSame { return perNome == .orderedAscending }
        return (a.marca ?? "").localizedStandardCompare(b.marca ?? "") == .orderedAscending
    }
}

extension Dispensa {
    /// I prodotti che corrispondono alla ricerca, divisi per categoria principale in ordine alfabetico,
    /// con "Senza categoria" in fondo; i gruppi vuoti non compaiono.
    func gruppiDiProdotti(cercando ricerca: String = "") -> [GruppoProdotti] {
        let trovati = (prodotti ?? []).filter { $0.corrisponde(a: ricerca) }
        // I gruppi nascono dai prodotti trovati: così nessun prodotto può restare fuori dall'elenco.
        var principali: [UUID: Categoria] = [:]
        var perCategoria: [UUID?: [Prodotto]] = [:]
        for prodotto in trovati {
            let principale = prodotto.categoriaPrincipale
            if let principale { principali[principale.id] = principale }
            perCategoria[principale?.id, default: []].append(prodotto)
        }

        var gruppi = principali.values
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
            .map { categoria in
                GruppoProdotti(
                    categoria: categoria,
                    prodotti: (perCategoria[categoria.id] ?? []).sorted(by: Prodotto.ordinePerNomeEMarca)
                )
            }
        if let senza = perCategoria[nil] {
            gruppi.append(GruppoProdotti(categoria: nil, prodotti: senza.sorted(by: Prodotto.ordinePerNomeEMarca)))
        }
        return gruppi
    }
}
