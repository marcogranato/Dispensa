//
//  Anteprime.swift
//  Dispensa
//

#if DEBUG
import Foundation
import SwiftData

extension ModelContainer {
    /// Database in memoria con dati di esempio, da usare solo nei `#Preview`.
    static let anteprima: ModelContainer = {
        let configurazione = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: SchemaDispensa.schema, configurations: [configurazione])
        inserisciDatiDiEsempio(in: container.mainContext)
        return container
    }()
}

private func inserisciDatiDiEsempio(in context: ModelContext) {
    let casa = Dispensa(nome: "Casa")
    let mare = Dispensa(nome: "Casa al mare")
    context.insert(casa)
    context.insert(mare)

    let cucina = Ubicazione(nome: "Cucina")
    let cantina = Ubicazione(nome: "Cantina")
    for ubicazione in [cucina, cantina] {
        context.insert(ubicazione)
        ubicazione.dispensa = casa
    }

    let frigo = Struttura(nome: "Frigorifero", tipo: .frigorifero)
    frigo.numeroRipiani = 4
    frigo.numeroCassetti = 2
    frigo.ubicazione = cucina
    let congelatore = Struttura(nome: "Congelatore", tipo: .congelatore)
    congelatore.numeroCassetti = 3
    congelatore.ubicazione = cantina
    let scaffale = Struttura(nome: "Scaffale vini", tipo: .scaffale)
    scaffale.numeroRipiani = 5
    scaffale.ubicazione = cantina
    for struttura in [frigo, congelatore, scaffale] {
        context.insert(struttura)
        struttura.dispensa = casa
    }

    let biscotti = Prodotto(nome: "Biscotti")
    biscotti.quantitaPerParte = 150
    biscotti.unita = .grammi
    biscotti.partiPerConfezione = 6
    context.insert(biscotti)
    biscotti.dispensa = casa

    let articolo = Articolo(partiTotali: 6)
    articolo.partiRimaste = 4
    articolo.quantitaPerParte = 150
    articolo.unita = .grammi
    articolo.dataScadenza = Calendar.current.date(byAdding: .day, value: 20, to: .now)
    context.insert(articolo)
    articolo.prodotto = biscotti
    articolo.struttura = frigo
    articolo.dispensa = casa
}
#endif
