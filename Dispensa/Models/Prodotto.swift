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
    /// Vecchio campo per un solo codice: al primo avvio il valore passa in `codici` e il campo si svuota
    /// (vedi `spostaCodiciVecchi()`). Resta solo per non perdere i dati salvati prima.
    var codiceBarre: String?
    var quantitaPerParte: Double?
    var unitaRaw: String?
    var partiPerConfezione: Int = 1
    /// Che cosa è ogni parte (pacchetto, bottiglia…); conta solo se le parti sono più di una.
    var tipoParteRaw: String?
    /// Emoji facoltativa; se manca si usa quella della categoria.
    var icona: String?
    var descrizione: String?
    var note: String?
    /// Foto ridotta (vedi Services/ElaborazioneImmagini.swift), salvata fuori dal database.
    @Attribute(.externalStorage) var immagine: Data?
    /// Versione piccola della foto, per le righe degli elenchi.
    var miniatura: Data?
    var dataCreazione: Date = Date.now

    var dispensa: Dispensa?

    /// Il nodo più preciso dell'albero delle categorie; `nil` se senza categoria.
    var categoria: Categoria?

    /// Hashtag (es. #senzaglutine).
    @Relationship(deleteRule: .nullify, inverse: \Etichetta.prodotti)
    var etichette: [Etichetta]? = []

    @Relationship(deleteRule: .nullify, inverse: \Articolo.prodotto)
    var articoli: [Articolo]? = []

    /// I codici a barre del prodotto; eliminando il prodotto si eliminano anche loro.
    @Relationship(deleteRule: .cascade, inverse: \CodiceBarre.prodotto)
    var codici: [CodiceBarre]? = []

    var unita: Unita? {
        get { unitaRaw.flatMap(Unita.init(rawValue:)) }
        set { unitaRaw = newValue?.rawValue }
    }

    var tipoParte: TipoParte? {
        get { tipoParteRaw.flatMap(TipoParte.init(rawValue:)) }
        set { tipoParteRaw = newValue?.rawValue }
    }

    /// Es. "Penne rigate · Barilla", o solo il nome se la marca manca.
    var nomeConMarca: String {
        guard let marca, !marca.isEmpty else { return nome }
        return "\(nome) · \(marca)"
    }

    /// Confezione composta da più parti (es. 4 pacchetti di biscotti).
    var isMultipack: Bool { partiPerConfezione > 1 }

    /// Quantità netta dell'intera confezione: parti × quantità per parte. Calcolata, mai salvata.
    var quantitaTotale: Double? {
        quantitaPerParte.map { $0 * Double(max(partiPerConfezione, 1)) }
    }

    /// L'emoji del prodotto o, se manca, quella della sua categoria (o di un suo genitore).
    var iconaEffettiva: String? {
        if let icona, !icona.trimmingCharacters(in: .whitespaces).isEmpty {
            return icona
        }
        return categoria?.iconaEffettiva
    }

    init(nome: String) {
        self.nome = nome
    }
}
