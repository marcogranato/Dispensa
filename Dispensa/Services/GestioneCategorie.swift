//
//  GestioneCategorie.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Errori delle operazioni sull'albero delle categorie.
enum ErroreGestioneCategorie: LocalizedError, Equatable {
    case nomeVuoto
    case nomeDuplicato
    case troppiLivelli
    case spostamentoCircolare
    case categoriaDiAltraDispensa

    var errorDescription: String? {
        switch self {
        case .nomeVuoto:
            String(localized: "Scrivi il nome della categoria.")
        case .nomeDuplicato:
            String(localized: "Allo stesso livello esiste già una categoria con questo nome.")
        case .troppiLivelli:
            String(localized: "Le categorie possono avere al massimo tre livelli: categoria, sottocategoria e tipologia.")
        case .spostamentoCircolare:
            String(localized: "Una categoria non può stare dentro sé stessa o una sua sottocategoria.")
        case .categoriaDiAltraDispensa:
            String(localized: "La categoria appartiene a un'altra dispensa.")
        }
    }
}

extension Categoria {
    /// Livelli occupati da questa categoria insieme alle sue sottocategorie (1 se non ne ha).
    var altezza: Int {
        let livelloProprio = livello
        let piuProfondo = discendenti.map(\.livello).max() ?? livelloProprio
        return piuProfondo - livelloProprio + 1
    }

    /// Riduce il testo a una sola emoji (o carattere); `nil` se vuoto.
    static func iconaNormalizzata(_ testo: String?) -> String? {
        guard let primo = testo?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return nil }
        return String(primo)
    }
}

extension Dispensa {
    /// Categorie senza genitore, in ordine alfabetico.
    var categoriePrincipali: [Categoria] {
        (categorie ?? [])
            .filter { $0.genitore == nil }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    /// Tutto l'albero in ordine di lettura: ogni categoria seguita dalle sue sottocategorie.
    var categorieInOrdine: [Categoria] {
        var risultato: [Categoria] = []
        var visitati: Set<UUID> = []
        func aggiungi(_ categoria: Categoria) {
            guard visitati.insert(categoria.id).inserted else { return }
            risultato.append(categoria)
            categoria.sottocategorieOrdinate.forEach(aggiungi)
        }
        categoriePrincipali.forEach(aggiungi)
        return risultato
    }
}

extension ModelContext {
    /// Crea una categoria dentro `genitore` (o principale se `nil`).
    @discardableResult
    func creaCategoria(
        nome: String,
        icona: String? = nil,
        sotto genitore: Categoria?,
        in dispensa: Dispensa
    ) throws -> Categoria {
        try verificaGenitore(genitore, in: dispensa, altezza: 1)
        let nome = try nomeValido(nome, sotto: genitore, in: dispensa, escludendo: nil)

        let categoria = Categoria(nome: nome)
        insert(categoria)
        categoria.dispensa = dispensa
        categoria.genitore = genitore
        categoria.icona = Categoria.iconaNormalizzata(icona)
        return categoria
    }

    /// Cambia nome, icona e posizione nell'albero; le sottocategorie si spostano insieme alla categoria.
    func modificaCategoria(
        _ categoria: Categoria,
        nome: String,
        icona: String?,
        sotto genitore: Categoria?
    ) throws {
        guard let dispensa = categoria.dispensa else { throw ErroreGestioneCategorie.categoriaDiAltraDispensa }
        if genitore !== categoria.genitore {
            if let genitore, genitore === categoria || categoria.discendenti.contains(where: { $0 === genitore }) {
                throw ErroreGestioneCategorie.spostamentoCircolare
            }
            try verificaGenitore(genitore, in: dispensa, altezza: categoria.altezza)
        }
        let nome = try nomeValido(nome, sotto: genitore, in: dispensa, escludendo: categoria)

        categoria.nome = nome
        categoria.icona = Categoria.iconaNormalizzata(icona)
        categoria.genitore = genitore
    }

    /// Elimina la categoria con tutte le sue sottocategorie.
    /// I loro prodotti passano alla categoria superiore (o restano senza categoria).
    func eliminaCategoria(_ categoria: Categoria) {
        let destinazione = categoria.genitore
        let sottoalbero = [categoria] + categoria.discendenti
        for nodo in sottoalbero {
            for prodotto in nodo.prodotti ?? [] {
                prodotto.categoria = destinazione
            }
        }
        for nodo in sottoalbero.reversed() {
            delete(nodo)
        }
    }

    /// Controlla che un sottoalbero alto `altezza` livelli possa stare dentro `genitore`.
    private func verificaGenitore(_ genitore: Categoria?, in dispensa: Dispensa, altezza: Int) throws {
        guard let genitore else { return }
        guard genitore.dispensa === dispensa else { throw ErroreGestioneCategorie.categoriaDiAltraDispensa }
        guard genitore.livello + altezza <= Categoria.livelliMassimi else { throw ErroreGestioneCategorie.troppiLivelli }
    }

    /// Nome ripulito dagli spazi, non vuoto e non già usato allo stesso livello (maiuscole e accenti non contano).
    private func nomeValido(
        _ nome: String,
        sotto genitore: Categoria?,
        in dispensa: Dispensa,
        escludendo esclusa: Categoria?
    ) throws -> String {
        let nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nome.isEmpty else { throw ErroreGestioneCategorie.nomeVuoto }
        let fratelli = genitore?.sottocategorie ?? dispensa.categoriePrincipali
        let duplicato = fratelli.contains {
            $0 !== esclusa && $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        guard !duplicato else { throw ErroreGestioneCategorie.nomeDuplicato }
        return nome
    }
}
