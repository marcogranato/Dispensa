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

    let categorie = context.inserisciCategorieDiProva(in: casa)

    let biscotti = Prodotto(nome: "Biscotti")
    biscotti.quantitaPerParte = 150
    biscotti.unita = .grammi
    biscotti.partiPerConfezione = 6
    biscotti.tipoParte = .pacchetto
    context.insert(biscotti)
    biscotti.dispensa = casa
    biscotti.categoria = categorie["Biscotti secchi"]

    let penne = Prodotto(nome: "Penne rigate")
    penne.marca = "Barilla"
    penne.quantitaPerParte = 500
    penne.unita = .grammi
    penne.descrizione = "Pasta di semola di grano duro"
    context.insert(penne)
    penne.dispensa = casa
    penne.categoria = categorie["Pasta di semola"]

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

extension ModelContext {
    /// Piccolo albero di categorie per anteprime e prove a mano (solo nella versione di sviluppo).
    /// Non è l'elenco predefinito definitivo, che verrà deciso in una fase successiva.
    /// - Returns: le categorie create, per nome.
    @discardableResult
    func inserisciCategorieDiProva(in dispensa: Dispensa) -> [String: Categoria] {
        // (nome, emoji, nome del genitore)
        let albero: [(String, String?, String?)] = [
            ("Pasta e riso", "🍝", nil),
            ("Pasta secca", nil, "Pasta e riso"),
            ("Pasta di semola", nil, "Pasta secca"),
            ("Riso", "🍚", "Pasta e riso"),
            ("Pane e prodotti da forno", "🥖", nil),
            ("Biscotti", "🍪", "Pane e prodotti da forno"),
            ("Biscotti secchi", nil, "Biscotti"),
            ("Latticini", "🧀", nil),
            ("Conserve", "🥫", nil),
        ]
        var create: [String: Categoria] = [:]
        for (nome, icona, genitore) in albero {
            // Le categorie già presenti (stesso nome allo stesso livello) vengono saltate.
            create[nome] = try? creaCategoria(nome: nome, icona: icona, sotto: genitore.flatMap { create[$0] }, in: dispensa)
        }
        return create
    }
}
#endif
