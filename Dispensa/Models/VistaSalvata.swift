//
//  VistaSalvata.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Gli elenchi che hanno filtri e ordinamento, e quindi viste salvate.
enum TipoElenco: String, CaseIterable, Identifiable {
    case articoli, storico, struttura, prodotti

    var id: Self { self }
}

/// Filtri e ordine di un elenco salvati con un nome (es. "Da ricomprare"), per richiamarli con un tocco.
/// Appartiene alla dispensa: in futuro sarà condivisa con lei. Le viste della scheda della struttura
/// valgono per tutte le strutture.
@Model
final class VistaSalvata {
    var id: UUID = UUID()
    var nome: String = ""
    var tipoRaw: String = TipoElenco.articoli.rawValue
    /// `FiltroArticoli` o `FiltroProdotti` in JSON (vedi Services/GestioneViste.swift).
    var filtroJSON: Data?
    var criterioRaw: String?
    var crescente: Bool = true
    /// "Raggruppa per prodotto" (solo per gli elenchi di articoli presenti); `nil` = come all'apertura dell'elenco.
    var raggruppa: Bool?
    /// La vista con cui si apre il suo elenco (al massimo una per elenco).
    var predefinita: Bool = false
    var dataCreazione: Date = Date.now

    var dispensa: Dispensa?

    var tipo: TipoElenco? {
        get { TipoElenco(rawValue: tipoRaw) }
        set { tipoRaw = (newValue ?? .articoli).rawValue }
    }

    init(nome: String, tipo: TipoElenco) {
        self.nome = nome
        self.tipoRaw = tipo.rawValue
    }
}
