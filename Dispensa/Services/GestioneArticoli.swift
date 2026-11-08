//
//  GestioneArticoli.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Errori delle operazioni sugli articoli e sui prodotti.
enum ErroreGestioneArticoli: LocalizedError, Equatable {
    case partiNonValide
    case articoloNonPresente
    case articoloNonNelloStorico
    case strutturaDiAltraDispensa
    case strutturaMancante
    case prodottoConArticoliPresenti

    var errorDescription: String? {
        switch self {
        case .partiNonValide:
            String(localized: "Il numero di parti non è valido.")
        case .articoloNonPresente:
            String(localized: "L'articolo non è più in dispensa.")
        case .articoloNonNelloStorico:
            String(localized: "L'articolo non è nello storico.")
        case .strutturaDiAltraDispensa:
            String(localized: "La struttura appartiene a un'altra dispensa.")
        case .strutturaMancante:
            String(localized: "Scegli una struttura in cui rimettere l'articolo.")
        case .prodottoConArticoliPresenti:
            String(localized: "Il prodotto ha ancora articoli in dispensa.")
        }
    }
}

extension ModelContext {
    /// Preleva `parti` parti intere. Quando non ne restano, l'articolo esce come consumato.
    func preleva(_ articolo: Articolo, parti: Int = 1) throws {
        try verificaPresente(articolo, parti: parti)
        articolo.partiRimaste -= parti
        if articolo.partiRimaste == 0 {
            esci(articolo, come: .consumato)
        }
    }

    /// Butta `parti` parti intere per il motivo indicato. Quando non ne restano, l'articolo esce come buttato.
    func butta(_ articolo: Articolo, parti: Int, motivo: MotivoScarto) throws {
        try verificaPresente(articolo, parti: parti)
        articolo.partiRimaste -= parti
        articolo.partiButtate += parti
        articolo.motivoScarto = motivo
        if articolo.partiRimaste == 0 {
            esci(articolo, come: .buttato)
        }
    }

    /// Sposta l'articolo in un'altra struttura della stessa dispensa.
    /// Se `parti` è minore delle parti rimaste, la confezione si divide: le parti spostate
    /// diventano un nuovo articolo con le stesse date.
    /// - Returns: l'articolo che si trova ora in `destinazione`.
    @discardableResult
    func sposta(_ articolo: Articolo, in destinazione: Struttura, parti: Int? = nil) throws -> Articolo {
        let parti = parti ?? articolo.partiRimaste
        try verificaPresente(articolo, parti: parti)
        guard destinazione.dispensa === articolo.dispensa else {
            throw ErroreGestioneArticoli.strutturaDiAltraDispensa
        }

        guard parti < articolo.partiRimaste else {
            articolo.struttura = destinazione
            return articolo
        }

        let spostato = Articolo(partiTotali: parti)
        spostato.quantitaPerParte = articolo.quantitaPerParte
        spostato.unitaRaw = articolo.unitaRaw
        spostato.dataInserimento = articolo.dataInserimento
        spostato.dataProduzione = articolo.dataProduzione
        spostato.dataScadenza = articolo.dataScadenza
        insert(spostato)
        spostato.prodotto = articolo.prodotto
        spostato.dispensa = articolo.dispensa
        spostato.struttura = destinazione

        articolo.partiTotali -= parti
        articolo.partiRimaste -= parti
        return spostato
    }

    /// Rimette in dispensa un articolo uscito per errore, con `parti` parti rimaste.
    /// Se l'articolo non ha più una struttura (perché eliminata), va indicata `struttura`.
    func rimettiInDispensa(_ articolo: Articolo, parti: Int = 1, in struttura: Struttura? = nil) throws {
        guard articolo.stato != .attivo else {
            throw ErroreGestioneArticoli.articoloNonNelloStorico
        }
        guard (1...articolo.partiTotali).contains(parti) else {
            throw ErroreGestioneArticoli.partiNonValide
        }
        guard let destinazione = struttura ?? articolo.struttura else {
            throw ErroreGestioneArticoli.strutturaMancante
        }
        guard destinazione.dispensa === articolo.dispensa else {
            throw ErroreGestioneArticoli.strutturaDiAltraDispensa
        }

        articolo.struttura = destinazione
        articolo.partiRimaste = parti
        articolo.partiButtate = min(articolo.partiButtate, articolo.partiTotali - parti)
        if articolo.partiButtate == 0 {
            articolo.motivoScarto = nil
        }
        articolo.stato = .attivo
        articolo.dataUscita = nil
    }

    /// Elimina gli articoli indicati dallo storico. Gli articoli ancora in dispensa vengono ignorati.
    func eliminaDalloStorico(_ articoli: [Articolo]) {
        for articolo in articoli where articolo.stato != .attivo {
            delete(articolo)
        }
    }

    /// Elimina tutto lo storico di una dispensa.
    func svuotaStorico(di dispensa: Dispensa) {
        eliminaDalloStorico(dispensa.articoli ?? [])
    }

    /// Elimina un prodotto insieme ai suoi articoli nello storico.
    /// Non è possibile se il prodotto ha ancora articoli in dispensa.
    func eliminaProdotto(_ prodotto: Prodotto) throws {
        let articoli = prodotto.articoli ?? []
        guard !articoli.contains(where: { $0.stato == .attivo }) else {
            throw ErroreGestioneArticoli.prodottoConArticoliPresenti
        }
        eliminaDalloStorico(articoli)
        delete(prodotto)
    }

    private func verificaPresente(_ articolo: Articolo, parti: Int) throws {
        guard articolo.stato == .attivo else {
            throw ErroreGestioneArticoli.articoloNonPresente
        }
        guard parti >= 1, parti <= articolo.partiRimaste else {
            throw ErroreGestioneArticoli.partiNonValide
        }
    }

    /// L'articolo esce dalla dispensa: va nello storico, oppure viene eliminato se lo storico è disattivato.
    private func esci(_ articolo: Articolo, come stato: StatoArticolo) {
        if articolo.dispensa?.storicoAbilitato ?? true {
            articolo.stato = stato
            articolo.dataUscita = .now
        } else {
            delete(articolo)
        }
    }
}
