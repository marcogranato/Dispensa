//
//  Etichetta.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Hashtag assegnabile ai prodotti (es. #senzaglutine, #colazione), per raggruppamenti trasversali.
/// La classificazione principale è invece l'albero delle `Categoria`.
@Model
final class Etichetta {
    var id: UUID = UUID()
    var nome: String = ""
    var coloreRaw: String?

    var dispensa: Dispensa?
    var prodotti: [Prodotto]? = []

    /// Colore facoltativo; senza colore l'etichetta è mostrata in grigio chiaro.
    var colore: ColoreEtichetta? {
        get { coloreRaw.flatMap(ColoreEtichetta.init(rawValue:)) }
        set { coloreRaw = newValue?.rawValue }
    }

    /// Es. "#colazione" (il nome si salva senza cancelletto).
    var nomeConCancelletto: String { "#\(nome)" }

    init(nome: String) {
        self.nome = nome
    }
}
