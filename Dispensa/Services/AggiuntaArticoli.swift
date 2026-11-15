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
    /// Il prodotto con questo nome e questa marca, se esiste. Maiuscole, accenti e spazi non contano;
    /// una marca vuota corrisponde solo ai prodotti senza marca.
    func prodotto(nominato nome: String, marca: String?) -> Prodotto? {
        (prodotti ?? []).first {
            Self.testoEquivalente($0.nome, nome) && Self.testoEquivalente($0.marca, marca)
        }
    }

    /// Un prodotto con lo stesso nome, di qualunque marca, da cui copiare categoria e tipo di parte.
    /// Preferisce quelli già classificati.
    func prodottoOmonimo(nominato nome: String) -> Prodotto? {
        let omonimi = (prodotti ?? []).filter { Self.testoEquivalente($0.nome, nome) }
        return omonimi.first { $0.categoria != nil } ?? omonimi.first
    }

    /// Vero se i due testi sono uguali senza contare maiuscole, accenti e spazi ai lati;
    /// `nil` e testo vuoto sono equivalenti.
    static func testoEquivalente(_ primo: String?, _ secondo: String?) -> Bool {
        let a = primo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let b = secondo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return a.compare(b, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }
}

extension ModelContext {
    /// Restituisce il prodotto con questo nome e questa marca; se non esiste lo crea, usando `dati`
    /// come confezione predefinita e la categoria e il tipo di parte indicati.
    /// Un prodotto nuovo prende l'emoji di un prodotto con lo stesso nome, se ce n'è uno.
    func trovaOCreaProdotto(
        nominato nome: String,
        marca: String? = nil,
        in dispensa: Dispensa,
        dati: DatiArticolo,
        categoria: Categoria? = nil,
        tipoParte: TipoParte? = nil
    ) -> Prodotto {
        if let esistente = dispensa.prodotto(nominato: nome, marca: marca) {
            return esistente
        }
        let marca = marca?.trimmingCharacters(in: .whitespacesAndNewlines)
        let nuovo = Prodotto(nome: nome.trimmingCharacters(in: .whitespacesAndNewlines))
        nuovo.marca = (marca?.isEmpty ?? true) ? nil : marca
        nuovo.partiPerConfezione = dati.partiTotali
        nuovo.quantitaPerParte = dati.quantitaPerParte
        nuovo.unita = dati.unita
        nuovo.tipoParte = dati.partiTotali > 1 ? tipoParte : nil
        nuovo.icona = dispensa.prodottoOmonimo(nominato: nome)?.icona
        insert(nuovo)
        nuovo.dispensa = dispensa
        nuovo.categoria = categoria
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
