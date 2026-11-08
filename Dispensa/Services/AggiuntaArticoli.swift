//
//  AggiuntaArticoli.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Valori di un articolo da creare o modificare.
struct DatiArticolo {
    var partiTotali = 1
    var quantitaPerParte: Double?
    var unita: Unita?
    var dataInserimento = Date.now
    var dataProduzione: Date?
    var dataScadenza: Date?

    /// Valori proposti per un nuovo articolo del prodotto.
    init(prodotto: Prodotto? = nil) {
        if let prodotto {
            partiTotali = prodotto.partiPerConfezione
            quantitaPerParte = prodotto.quantitaPerParte
            unita = prodotto.unita
        }
    }

    init(articolo: Articolo) {
        partiTotali = articolo.partiTotali
        quantitaPerParte = articolo.quantitaPerParte
        unita = articolo.unita
        dataInserimento = articolo.dataInserimento
        dataProduzione = articolo.dataProduzione
        dataScadenza = articolo.dataScadenza
    }

    func applica(a articolo: Articolo) {
        articolo.partiTotali = partiTotali
        articolo.partiRimaste = min(articolo.partiRimaste, partiTotali)
        articolo.quantitaPerParte = quantitaPerParte
        articolo.unita = unita
        articolo.dataInserimento = dataInserimento
        articolo.dataProduzione = dataProduzione
        articolo.dataScadenza = dataScadenza
    }
}

extension Dispensa {
    /// Il prodotto con questo nome (senza distinguere maiuscole e accenti), se esiste.
    func prodotto(nominato nome: String) -> Prodotto? {
        let nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        return (prodotti ?? []).first {
            $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }
}

extension ModelContext {
    /// Restituisce il prodotto con questo nome; se non esiste lo crea, usando `dati` come valori predefiniti.
    func trovaOCreaProdotto(nominato nome: String, in dispensa: Dispensa, dati: DatiArticolo) -> Prodotto {
        if let esistente = dispensa.prodotto(nominato: nome) {
            return esistente
        }
        let nuovo = Prodotto(nome: nome.trimmingCharacters(in: .whitespacesAndNewlines))
        nuovo.partiPerConfezione = dati.partiTotali
        nuovo.quantitaPerParte = dati.quantitaPerParte
        nuovo.unita = dati.unita
        insert(nuovo)
        nuovo.dispensa = dispensa
        return nuovo
    }

    /// Crea `confezioni` articoli uguali del prodotto nella struttura.
    @discardableResult
    func aggiungiArticoli(_ dati: DatiArticolo, prodotto: Prodotto, struttura: Struttura, confezioni: Int = 1) -> [Articolo] {
        (0..<max(confezioni, 1)).map { _ in
            let articolo = Articolo(partiTotali: dati.partiTotali)
            dati.applica(a: articolo)
            insert(articolo)
            articolo.prodotto = prodotto
            articolo.struttura = struttura
            articolo.dispensa = struttura.dispensa
            return articolo
        }
    }
}
