//
//  CodiceBarre.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Un codice a barre (o QR) di un prodotto. Un prodotto può averne più d'uno
/// (es. il cartone di latte singolo e la confezione da sei); un codice appartiene a un solo prodotto
/// della dispensa (regola in Services/GestioneCodici.swift).
@Model
final class CodiceBarre {
    var codice: String = ""
    var dataCreazione: Date = Date.now

    var prodotto: Prodotto?

    init(codice: String) {
        self.codice = codice
    }
}
