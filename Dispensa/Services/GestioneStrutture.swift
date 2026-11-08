//
//  GestioneStrutture.swift
//  Dispensa
//

import SwiftData

extension ModelContext {
    /// Elimina una struttura insieme ai suoi articoli attivi.
    /// Gli articoli nello storico restano, senza struttura.
    func eliminaStruttura(_ struttura: Struttura) {
        for articolo in struttura.articoliAttivi {
            delete(articolo)
        }
        delete(struttura)
    }
}
