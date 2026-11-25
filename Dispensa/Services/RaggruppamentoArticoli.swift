//
//  RaggruppamentoArticoli.swift
//  Dispensa
//

import Foundation

/// Gli articoli presenti dello stesso prodotto, mostrati in una sola riga ("Gran Cereale ×3").
/// Un articolo senza prodotto resta da solo.
struct GruppoArticoli: Identifiable {
    /// Le confezioni, nell'ordine dell'elenco (dopo ricerca, filtri e ordinamento). Mai vuoto.
    let articoli: [Articolo]

    /// Una confezione sola ha l'identità dell'articolo, così senza raggruppamento non ci sono doppioni.
    var id: UUID { multiplo ? (prodotto?.id ?? articoli[0].id) : articoli[0].id }

    var prodotto: Prodotto? { articoli[0].prodotto }

    var confezioni: Int { articoli.count }

    /// Vero se le confezioni sono almeno due: altrimenti la riga è quella del singolo articolo.
    var multiplo: Bool { articoli.count > 1 }

    /// Le parti rimaste in tutte le confezioni.
    var partiRimaste: Int { articoli.reduce(0) { $0 + $1.partiRimaste } }

    /// Vero se almeno una confezione è fatta di più parti (es. scatola con 6 pacchi).
    var conPiuParti: Bool { articoli.contains { $0.partiTotali > 1 } }

    /// La data di scadenza più vicina tra le confezioni.
    var scadenzaPiuVicina: Date? { articoli.compactMap(\.dataScadenza).min() }

    /// Lo stato peggiore tra le confezioni: basta una scaduta perché il gruppo lo sia.
    func statoPeggiore(oggi: Date = .now, calendario: Calendar = .current) -> StatoScadenza {
        articoli
            .map { $0.statoScadenza(oggi: oggi, calendario: calendario) }
            .min { $0.gravita < $1.gravita } ?? .senzaScadenza
    }

    /// I nomi delle strutture in cui si trovano le confezioni, senza ripetizioni, nell'ordine dell'elenco.
    var strutture: [String] {
        var viste = Set<String>()
        return articoli.compactMap(\.struttura?.nome).filter { viste.insert($0).inserted }
    }

    /// La confezione da cui prelevare: quella che scade prima (senza data in fondo);
    /// a parità, una già aperta, poi la più vecchia.
    var daPrelevare: Articolo {
        articoli.min { a, b in
            switch (a.dataScadenza, b.dataScadenza) {
            case let (scadenzaA?, scadenzaB?) where !Calendar.current.isDate(scadenzaA, inSameDayAs: scadenzaB):
                return scadenzaA < scadenzaB
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                let apertaA = a.partiRimaste < a.partiTotali
                let apertaB = b.partiRimaste < b.partiTotali
                if apertaA != apertaB { return apertaA }
                return a.dataInserimento < b.dataInserimento
            }
        } ?? articoli[0]
    }
}

extension StatoScadenza {
    /// Più è piccolo, più è urgente.
    var gravita: Int {
        switch self {
        case .scaduto: 0
        case .inScadenza: 1
        case .valido: 2
        case .senzaScadenza: 3
        }
    }
}

enum RaggruppamentoArticoli {
    /// Riunisce gli articoli dello stesso prodotto. Ogni gruppo prende il posto della sua prima confezione
    /// nell'elenco, così l'ordine scelto resta valido (per scadenza conta la data più vicina).
    static func raggruppa(_ articoli: [Articolo]) -> [GruppoArticoli] {
        var ordine: [UUID] = []
        var perChiave: [UUID: [Articolo]] = [:]
        for articolo in articoli {
            let chiave = articolo.prodotto?.id ?? articolo.id
            if perChiave[chiave] == nil {
                ordine.append(chiave)
            }
            perChiave[chiave, default: []].append(articolo)
        }
        return ordine.compactMap { perChiave[$0].map(GruppoArticoli.init(articoli:)) }
    }
}
