//
//  FiltriArticoli.swift
//  Dispensa
//

import Foundation

/// Intervallo di giorni per filtrare una data: "dal" e "al" facoltativi, estremi compresi.
/// Contano solo i giorni, non le ore.
struct IntervalloDate: Equatable {
    var dal: Date?
    var al: Date?

    var attivo: Bool { dal != nil || al != nil }

    /// Vero se l'intervallo non è impostato, oppure se la data c'è e cade dentro.
    /// Un articolo senza quella data è escluso quando l'intervallo è impostato.
    func include(_ data: Date?, calendario: Calendar = .current) -> Bool {
        guard attivo else { return true }
        guard let data else { return false }
        let giorno = calendario.startOfDay(for: data)
        if let dal, giorno < calendario.startOfDay(for: dal) { return false }
        if let al, giorno > calendario.startOfDay(for: al) { return false }
        return true
    }
}

/// Filtri sugli articoli (presenti o nello storico). Non viene salvato: i filtri salvati arriveranno nella fase 4.
///
/// Dentro un gruppo basta una delle scelte (frigorifero **o** dispensa); tra gruppi diversi
/// devono valere tutti (frigorifero **e** scaduti). Un gruppo vuoto non filtra.
struct FiltroArticoli: Equatable {
    var strutture: Set<UUID> = []
    var tipiStruttura: Set<TipoStruttura> = []
    /// Una categoria comprende le sue sottocategorie.
    var categorie: Set<UUID> = []
    var etichette: Set<UUID> = []
    var scadenze: Set<StatoScadenza> = []
    var inserimento = IntervalloDate()
    var produzione = IntervalloDate()
    var scadenza = IntervalloDate()
    /// Solo per lo storico.
    var uscita = IntervalloDate()
    /// Solo per lo storico: consumati e/o buttati.
    var esiti: Set<StatoArticolo> = []

    /// Quanti gruppi di filtri sono impostati.
    var numeroAttivi: Int {
        [
            !strutture.isEmpty, !tipiStruttura.isEmpty, !categorie.isEmpty, !etichette.isEmpty,
            !scadenze.isEmpty, inserimento.attivo, produzione.attivo, scadenza.attivo,
            uscita.attivo, !esiti.isEmpty,
        ].filter { $0 }.count
    }

    var vuoto: Bool { numeroAttivi == 0 }

    func include(_ articolo: Articolo, oggi: Date = .now, calendario: Calendar = .current) -> Bool {
        if !strutture.isEmpty {
            guard let struttura = articolo.struttura, strutture.contains(struttura.id) else { return false }
        }
        if !tipiStruttura.isEmpty {
            guard let struttura = articolo.struttura, tipiStruttura.contains(struttura.tipo) else { return false }
        }
        if !categorie.isEmpty {
            // Il percorso comprende la categoria del prodotto e tutte quelle superiori.
            let percorso = articolo.prodotto?.categoria?.percorso ?? []
            guard percorso.contains(where: { categorie.contains($0.id) }) else { return false }
        }
        if !etichette.isEmpty {
            let sue = articolo.prodotto?.etichette ?? []
            guard sue.contains(where: { etichette.contains($0.id) }) else { return false }
        }
        if !scadenze.isEmpty {
            guard scadenze.contains(articolo.statoScadenza(oggi: oggi, calendario: calendario)) else { return false }
        }
        if !esiti.isEmpty {
            guard esiti.contains(articolo.stato) else { return false }
        }
        return inserimento.include(articolo.dataInserimento, calendario: calendario)
            && produzione.include(articolo.dataProduzione, calendario: calendario)
            && scadenza.include(articolo.dataScadenza, calendario: calendario)
            && uscita.include(articolo.dataUscita, calendario: calendario)
    }

    /// Gli articoli che passano i filtri, nello stesso ordine.
    func applica(_ articoli: [Articolo], oggi: Date = .now, calendario: Calendar = .current) -> [Articolo] {
        guard !vuoto else { return articoli }
        return articoli.filter { include($0, oggi: oggi, calendario: calendario) }
    }
}
