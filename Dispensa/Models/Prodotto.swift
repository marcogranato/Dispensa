//
//  Prodotto.swift
//  Dispensa
//

import Foundation
import SwiftData

/// La "scheda" riutilizzabile di un prodotto (es. "Biscotti Oro Saiwa").
/// I valori di quantità sono predefiniti e vengono copiati nei nuovi articoli.
@Model
final class Prodotto {
    var id: UUID = UUID()
    var nome: String = ""
    var marca: String?
    var codiceBarre: String?
    var quantitaPerParte: Double?
    var unitaRaw: String?
    var partiPerConfezione: Int = 1
    @Attribute(.externalStorage) var immagine: Data?
    var dataCreazione: Date = Date.now

    var dispensa: Dispensa?

    @Relationship(deleteRule: .nullify, inverse: \Etichetta.prodotti)
    var etichette: [Etichetta]? = []

    @Relationship(deleteRule: .nullify, inverse: \Articolo.prodotto)
    var articoli: [Articolo]? = []

    var unita: Unita? {
        get { unitaRaw.flatMap(Unita.init(rawValue:)) }
        set { unitaRaw = newValue?.rawValue }
    }

    init(nome: String) {
        self.nome = nome
    }
}
