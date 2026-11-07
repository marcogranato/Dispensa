//
//  Articolo.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Un oggetto fisico presente in una struttura (es. "la scatola di biscotti nello scaffale").
/// Una confezione è composta da `partiTotali` parti; si preleva a parti intere.
@Model
final class Articolo {
    var id: UUID = UUID()
    var partiTotali: Int = 1
    var partiRimaste: Int = 1
    var quantitaPerParte: Double?
    var unitaRaw: String?
    var dataInserimento: Date = Date.now
    var dataProduzione: Date?
    var dataScadenza: Date?
    var statoRaw: String = StatoArticolo.attivo.rawValue
    var motivoScartoRaw: String?
    var partiButtate: Int = 0
    /// Data in cui l'articolo è stato consumato o buttato.
    var dataUscita: Date?

    var prodotto: Prodotto?
    var struttura: Struttura?
    var dispensa: Dispensa?

    var stato: StatoArticolo {
        get { StatoArticolo(rawValue: statoRaw) ?? .attivo }
        set { statoRaw = newValue.rawValue }
    }

    var motivoScarto: MotivoScarto? {
        get { motivoScartoRaw.flatMap(MotivoScarto.init(rawValue:)) }
        set { motivoScartoRaw = newValue?.rawValue }
    }

    var unita: Unita? {
        get { unitaRaw.flatMap(Unita.init(rawValue:)) }
        set { unitaRaw = newValue?.rawValue }
    }

    init(partiTotali: Int = 1) {
        self.partiTotali = partiTotali
        self.partiRimaste = partiTotali
    }
}
