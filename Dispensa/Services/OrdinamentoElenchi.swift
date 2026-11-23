//
//  OrdinamentoElenchi.swift
//  Dispensa
//

import Foundation

/// Un criterio con cui si può ordinare un elenco, con i nomi da mostrare nel menu "Ordina".
protocol CriterioOrdinamento: Hashable, Identifiable, RawRepresentable where RawValue == String {
    var nomeLocalizzato: LocalizedStringResource { get }
    /// Il verso proposto quando si sceglie il criterio (es. le date di uscita dalla più recente).
    var crescenteNaturale: Bool { get }
    /// Come si legge il verso crescente per questo criterio (es. "A → Z").
    var nomeCrescente: LocalizedStringResource { get }
    var nomeDecrescente: LocalizedStringResource { get }
}

/// Criterio e verso dell'ordine di un elenco. Non si salva: chiudendo l'app torna quello iniziale.
struct Ordine<Criterio: CriterioOrdinamento>: Equatable {
    /// Cambiando criterio il verso torna a quello naturale del nuovo criterio.
    var criterio: Criterio {
        didSet {
            if criterio != oldValue { crescente = criterio.crescenteNaturale }
        }
    }
    var crescente: Bool

    init(_ criterio: Criterio) {
        self.criterio = criterio
        self.crescente = criterio.crescenteNaturale
    }
}

// MARK: - Articoli

enum CriterioArticoli: String, CriterioOrdinamento, CaseIterable {
    case scadenza, nome, inserimento, struttura, uscita

    var id: Self { self }

    /// Criteri della scheda Articoli.
    static let perArticoli: [CriterioArticoli] = [.scadenza, .nome, .inserimento, .struttura]
    /// Criteri della scheda di una struttura (la struttura è sempre la stessa).
    static let perStruttura: [CriterioArticoli] = [.scadenza, .nome, .inserimento]
    /// Criteri dello storico.
    static let perStorico: [CriterioArticoli] = [.uscita, .nome, .scadenza]

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .scadenza: "Scadenza"
        case .nome: "Nome"
        case .inserimento: "Data di inserimento"
        case .struttura: "Struttura"
        case .uscita: "Data di uscita"
        }
    }

    var crescenteNaturale: Bool { self != .uscita }

    var nomeCrescente: LocalizedStringResource {
        switch self {
        case .scadenza: "Dalla più vicina"
        case .nome, .struttura: "A → Z"
        case .inserimento, .uscita: "Dalla meno recente"
        }
    }

    var nomeDecrescente: LocalizedStringResource {
        switch self {
        case .scadenza: "Dalla più lontana"
        case .nome, .struttura: "Z → A"
        case .inserimento, .uscita: "Dalla più recente"
        }
    }
}

typealias OrdineArticoli = Ordine<CriterioArticoli>

extension Ordine where Criterio == CriterioArticoli {
    /// Ordine iniziale delle schede Articoli e Struttura: dalla scadenza più vicina.
    static var articoli: OrdineArticoli { OrdineArticoli(.scadenza) }
    /// Ordine iniziale dello storico: dall'uscita più recente.
    static var storico: OrdineArticoli { OrdineArticoli(.uscita) }

    /// Ordina gli articoli. Date mancanti (e articoli senza struttura) vanno sempre in fondo,
    /// in tutti e due i versi; a parità si ordina per scadenza e poi per nome.
    func ordina(_ articoli: [Articolo]) -> [Articolo] {
        articoli.sorted(by: precede)
    }

    /// Vero se `a` viene prima di `b`.
    func precede(_ a: Articolo, _ b: Articolo) -> Bool {
        let principale: Bool?
        switch criterio {
        case .scadenza:
            principale = confrontaFacoltativi(a.dataScadenza, b.dataScadenza, crescente: crescente)
        case .inserimento:
            principale = confrontaFacoltativi(a.dataInserimento, b.dataInserimento, crescente: crescente)
        case .uscita:
            principale = confrontaFacoltativi(a.dataUscita, b.dataUscita, crescente: crescente)
        case .nome:
            principale = confrontaTesti(a.nomeVisualizzato, b.nomeVisualizzato, crescente: crescente)
        case .struttura:
            principale = confrontaFacoltativi(
                a.struttura.map { ChiaveTesto($0.nome) },
                b.struttura.map { ChiaveTesto($0.nome) },
                crescente: crescente
            )
        }
        if let principale { return principale }
        // Parità: scadenza più vicina, poi nome, sempre in verso crescente.
        if criterio != .scadenza, let perScadenza = confrontaFacoltativi(a.dataScadenza, b.dataScadenza, crescente: true) {
            return perScadenza
        }
        return confrontaTesti(a.nomeVisualizzato, b.nomeVisualizzato, crescente: true) ?? false
    }
}

// MARK: - Prodotti

enum CriterioProdotti: String, CriterioOrdinamento, CaseIterable {
    case nome, creazione, presenti

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .nome: "Nome"
        case .creazione: "Data di creazione"
        case .presenti: "Articoli presenti"
        }
    }

    var crescenteNaturale: Bool { self == .nome }

    var nomeCrescente: LocalizedStringResource {
        switch self {
        case .nome: "A → Z"
        case .creazione: "Dal meno recente"
        case .presenti: "Dal numero più basso"
        }
    }

    var nomeDecrescente: LocalizedStringResource {
        switch self {
        case .nome: "Z → A"
        case .creazione: "Dal più recente"
        case .presenti: "Dal numero più alto"
        }
    }
}

typealias OrdineProdotti = Ordine<CriterioProdotti>

extension Ordine where Criterio == CriterioProdotti {
    /// Ordine iniziale della scheda Prodotti: per nome, dalla A alla Z.
    static var prodotti: OrdineProdotti { OrdineProdotti(.nome) }

    /// Vero se `a` viene prima di `b`; a parità si ordina per nome e marca.
    func precede(_ a: Prodotto, _ b: Prodotto) -> Bool {
        let principale: Bool?
        switch criterio {
        case .nome:
            let perNome = confrontaTesti(a.nome, b.nome, crescente: crescente)
            principale = perNome ?? confrontaTesti(a.marca ?? "", b.marca ?? "", crescente: crescente)
        case .creazione:
            principale = confrontaFacoltativi(a.dataCreazione, b.dataCreazione, crescente: crescente)
        case .presenti:
            principale = confrontaFacoltativi(a.numeroArticoliPresenti, b.numeroArticoliPresenti, crescente: crescente)
        }
        return principale ?? Prodotto.ordinePerNomeEMarca(a, b)
    }
}

extension Prodotto {
    /// Quanti articoli di questo prodotto sono ora in dispensa.
    var numeroArticoliPresenti: Int {
        (articoli ?? []).filter { $0.stato == .attivo }.count
    }
}

// MARK: - Intestazioni delle tabelle

/// Collega l'intestazione di una colonna di tabella a un criterio: cliccandola si sceglie quel criterio,
/// cliccandola di nuovo si inverte il verso. L'ordine resta quello dello stato dell'elenco.
struct ComparatoreArticoli: SortComparator, Hashable {
    let criterio: CriterioArticoli
    var order: SortOrder

    /// Il comparatore di una colonna, con il verso naturale del criterio.
    init(_ criterio: CriterioArticoli) {
        self.criterio = criterio
        self.order = criterio.crescenteNaturale ? .forward : .reverse
    }

    init(_ ordine: OrdineArticoli) {
        self.criterio = ordine.criterio
        self.order = ordine.crescente ? .forward : .reverse
    }

    var ordine: OrdineArticoli {
        var ordine = OrdineArticoli(criterio)
        ordine.crescente = order == .forward
        return ordine
    }

    func compare(_ a: Articolo, _ b: Articolo) -> ComparisonResult {
        let ordine = self.ordine
        if ordine.precede(a, b) { return .orderedAscending }
        if ordine.precede(b, a) { return .orderedDescending }
        return .orderedSame
    }
}

struct ComparatoreProdotti: SortComparator, Hashable {
    let criterio: CriterioProdotti
    var order: SortOrder

    init(_ criterio: CriterioProdotti) {
        self.criterio = criterio
        self.order = criterio.crescenteNaturale ? .forward : .reverse
    }

    init(_ ordine: OrdineProdotti) {
        self.criterio = ordine.criterio
        self.order = ordine.crescente ? .forward : .reverse
    }

    var ordine: OrdineProdotti {
        var ordine = OrdineProdotti(criterio)
        ordine.crescente = order == .forward
        return ordine
    }

    func compare(_ a: Prodotto, _ b: Prodotto) -> ComparisonResult {
        let ordine = self.ordine
        if ordine.precede(a, b) { return .orderedAscending }
        if ordine.precede(b, a) { return .orderedDescending }
        return .orderedSame
    }
}

// MARK: - Confronti

/// Testo confrontato come nel Finder ("Latte 2" prima di "Latte 10", maiuscole e accenti non contano).
private struct ChiaveTesto: Comparable {
    let testo: String
    init(_ testo: String) { self.testo = testo }

    static func < (a: ChiaveTesto, b: ChiaveTesto) -> Bool {
        a.testo.localizedStandardCompare(b.testo) == .orderedAscending
    }

    static func == (a: ChiaveTesto, b: ChiaveTesto) -> Bool {
        a.testo.localizedStandardCompare(b.testo) == .orderedSame
    }
}

/// `true`/`false` se i valori sono diversi, `nil` se sono pari.
/// Un valore mancante va sempre dopo uno presente, qualunque sia il verso.
private func confrontaFacoltativi<T: Comparable>(_ a: T?, _ b: T?, crescente: Bool) -> Bool? {
    switch (a, b) {
    case let (a?, b?):
        if a == b { return nil }
        return crescente ? a < b : b < a
    case (_?, nil):
        return true
    case (nil, _?):
        return false
    case (nil, nil):
        return nil
    }
}

private func confrontaTesti(_ a: String, _ b: String, crescente: Bool) -> Bool? {
    confrontaFacoltativi(ChiaveTesto(a), ChiaveTesto(b), crescente: crescente)
}
