//
//  GestioneEtichette.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Errori delle operazioni sulle etichette.
enum ErroreGestioneEtichette: LocalizedError, Equatable {
    case nomeVuoto
    case nomeDuplicato

    var errorDescription: String? {
        switch self {
        case .nomeVuoto:
            String(localized: "Scrivi il nome dell'etichetta.")
        case .nomeDuplicato:
            String(localized: "Esiste già un'etichetta con questo nome.")
        }
    }
}

extension Etichetta {
    /// Il nome come si salva: senza cancelletti e senza spazi ("#Senza glutine" → "Senzaglutine").
    static func nomeNormalizzato(_ testo: String) -> String {
        String(testo.filter { $0 != "#" && !$0.isWhitespace })
    }

    /// Prodotti con questa etichetta, per nome e marca.
    var prodottiOrdinati: [Prodotto] {
        (prodotti ?? []).sorted(by: Prodotto.ordinePerNomeEMarca)
    }
}

extension Prodotto {
    /// Etichette del prodotto in ordine alfabetico.
    var etichetteOrdinate: [Etichetta] {
        (etichette ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }
}

extension Dispensa {
    /// Etichette della dispensa in ordine alfabetico.
    var etichetteOrdinate: [Etichetta] {
        (etichette ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }
}

extension ModelContext {
    /// Crea un'etichetta; il nome viene ripulito da cancelletti e spazi.
    @discardableResult
    func creaEtichetta(nome: String, colore: ColoreEtichetta? = nil, in dispensa: Dispensa) throws -> Etichetta {
        let nome = try nomeEtichettaValido(nome, in: dispensa, escludendo: nil)
        let etichetta = Etichetta(nome: nome)
        insert(etichetta)
        etichetta.dispensa = dispensa
        etichetta.colore = colore
        return etichetta
    }

    /// Cambia nome e colore di un'etichetta.
    func modificaEtichetta(_ etichetta: Etichetta, nome: String, colore: ColoreEtichetta?) throws {
        if let dispensa = etichetta.dispensa {
            etichetta.nome = try nomeEtichettaValido(nome, in: dispensa, escludendo: etichetta)
        } else {
            let nome = Etichetta.nomeNormalizzato(nome)
            guard !nome.isEmpty else { throw ErroreGestioneEtichette.nomeVuoto }
            etichetta.nome = nome
        }
        etichetta.colore = colore
    }

    /// Elimina un'etichetta: i prodotti restano, senza quell'etichetta.
    func eliminaEtichetta(_ etichetta: Etichetta) {
        etichetta.prodotti = []
        delete(etichetta)
    }

    /// Nome normalizzato, non vuoto e non già usato nella dispensa (maiuscole e accenti non contano).
    private func nomeEtichettaValido(_ nome: String, in dispensa: Dispensa, escludendo esclusa: Etichetta?) throws -> String {
        let nome = Etichetta.nomeNormalizzato(nome)
        guard !nome.isEmpty else { throw ErroreGestioneEtichette.nomeVuoto }
        let duplicato = (dispensa.etichette ?? []).contains {
            $0 !== esclusa && $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        guard !duplicato else { throw ErroreGestioneEtichette.nomeDuplicato }
        return nome
    }
}
