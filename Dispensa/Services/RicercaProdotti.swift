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

/// Il testo di una ricerca, già interpretato.
enum TestoRicerca {
    /// Testo vuoto (o il solo "#"): trova tutto.
    case tutto
    /// "#cola": cerca solo nei nomi delle etichette.
    case etichetta(String)
    /// Qualunque altro testo: cerca in nome, marca, categorie, etichette, codice (e struttura per gli articoli).
    case libero(String)

    init(_ ricerca: String) {
        let testo = ricerca.trimmingCharacters(in: .whitespacesAndNewlines)
        if testo.hasPrefix("#") {
            let nome = Etichetta.nomeNormalizzato(testo)
            self = nome.isEmpty ? .tutto : .etichetta(nome)
        } else {
            self = testo.isEmpty ? .tutto : .libero(testo)
        }
    }
}

extension Prodotto {
    /// Vero se il testo compare nel nome, nella marca, nel nome di una delle sue categorie
    /// (quella del prodotto o una superiore) o di una sua etichetta, oppure è esattamente il codice a barre.
    /// Un testo che inizia con "#" cerca solo nelle etichette ("#cola" trova #colazione).
    /// Maiuscole e accenti non contano; un testo vuoto trova tutto.
    func corrisponde(a ricerca: String) -> Bool {
        corrisponde(a: TestoRicerca(ricerca))
    }

    func corrisponde(a ricerca: TestoRicerca) -> Bool {
        switch ricerca {
        case .tutto:
            return true
        case .etichetta(let testo):
            return haEtichetta(che: testo)
        case .libero(let testo):
            return nome.localizedStandardContains(testo)
                || (marca?.localizedStandardContains(testo) ?? false)
                || codiceBarre == testo
                || (categoria?.percorso.contains { $0.nome.localizedStandardContains(testo) } ?? false)
                || haEtichetta(che: testo)
        }
    }

    private func haEtichetta(che testo: String) -> Bool {
        (etichette ?? []).contains { $0.nome.localizedStandardContains(testo) }
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

extension Articolo {
    /// Vero se il suo prodotto corrisponde alla ricerca (vedi `Prodotto.corrisponde(a:)`)
    /// o se il testo compare nel nome della sua struttura ("frigo" trova gli articoli del frigorifero).
    func corrisponde(a ricerca: String) -> Bool {
        let testo = TestoRicerca(ricerca)
        switch testo {
        case .tutto:
            return true
        case .etichetta:
            return prodotto?.corrisponde(a: testo) ?? false
        case .libero(let libero):
            if let prodotto {
                if prodotto.corrisponde(a: testo) { return true }
            } else if nomeVisualizzato.localizedStandardContains(libero) {
                return true
            }
            return struttura?.nome.localizedStandardContains(libero) ?? false
        }
    }
}

extension Dispensa {
    /// I prodotti che corrispondono alla ricerca, divisi per categoria principale in ordine alfabetico,
    /// con "Senza categoria" in fondo; i gruppi vuoti non compaiono.
    /// Dentro ogni gruppo i prodotti seguono `ordine` (vedi Services/OrdinamentoElenchi.swift).
    func gruppiDiProdotti(cercando ricerca: String = "", ordine: OrdineProdotti = .prodotti) -> [GruppoProdotti] {
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
                    prodotti: (perCategoria[categoria.id] ?? []).sorted(by: ordine.precede)
                )
            }
        if let senza = perCategoria[nil] {
            gruppi.append(GruppoProdotti(categoria: nil, prodotti: senza.sorted(by: ordine.precede)))
        }
        return gruppi
    }
}
