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

    init(nome: String) {
        self.nome = nome
    }
}
