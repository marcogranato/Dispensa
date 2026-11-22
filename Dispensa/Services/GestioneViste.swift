//
//  GestioneViste.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Errori delle operazioni sulle viste salvate.
enum ErroreGestioneViste: LocalizedError, Equatable {
    case nomeVuoto
    case nomeDuplicato

    var errorDescription: String? {
        switch self {
        case .nomeVuoto:
            String(localized: "Scrivi il nome della vista.")
        case .nomeDuplicato:
            String(localized: "Esiste già una vista con questo nome. Per cambiarla, applicala e scegli «Aggiorna».")
        }
    }
}

/// Un filtro che si può salvare in una vista.
protocol FiltroSalvabile: FiltroElenco, Codable {
    /// Toglie le scelte su elementi che non esistono più nella dispensa.
    func ripulito(per dispensa: Dispensa) -> Self
}

/// Lo stato di un elenco con filtri e ordinamento: filtro, ordine e vista salvata applicata.
/// Non viene salvato: chiudendo l'app o cambiando dispensa torna quello iniziale.
struct StatoElenco<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento>: Equatable {
    let tipo: TipoElenco
    /// I criteri del menu "Ordina" per questo elenco.
    let criteri: [Criterio]
    let ordineIniziale: Ordine<Criterio>

    var filtro = Filtro()
    var ordine: Ordine<Criterio>
    /// La vista salvata applicata per ultima, se c'è.
    var vista: UUID?

    init(tipo: TipoElenco, criteri: [Criterio], ordineIniziale: Ordine<Criterio>) {
        self.tipo = tipo
        self.criteri = criteri
        self.ordineIniziale = ordineIniziale
        self.ordine = ordineIniziale
    }

    /// Vero quando in cima all'elenco va mostrata la riga con la vista o i filtri attivi.
    var mostraRiga: Bool { !filtro.vuoto || vista != nil }

    /// Toglie i filtri e la vista; se c'era una vista, torna anche l'ordine iniziale.
    mutating func azzera() {
        filtro = Filtro()
        if vista != nil { ordine = ordineIniziale }
        vista = nil
    }

    /// Applica filtri e ordine di una vista salvata.
    mutating func applica(_ salvata: VistaSalvata, in dispensa: Dispensa) {
        filtro = salvata.filtro(Filtro.self).ripulito(per: dispensa)
        ordine = salvata.ordine(criteri: criteri, iniziale: ordineIniziale)
        vista = salvata.id
    }

    /// La vista applicata, se esiste ancora.
    func vistaApplicata(in dispensa: Dispensa) -> VistaSalvata? {
        guard let vista else { return nil }
        return (dispensa.viste ?? []).first { $0.id == vista && $0.tipo == tipo }
    }

    /// Vero se filtro o ordine sono cambiati rispetto alla vista.
    func differisce(da salvata: VistaSalvata, in dispensa: Dispensa) -> Bool {
        salvata.filtro(Filtro.self).ripulito(per: dispensa) != filtro
            || salvata.ordine(criteri: criteri, iniziale: ordineIniziale) != ordine
    }
}

typealias StatoArticoli = StatoElenco<FiltroArticoli, CriterioArticoli>
typealias StatoProdotti = StatoElenco<FiltroProdotti, CriterioProdotti>

extension StatoElenco where Filtro == FiltroArticoli, Criterio == CriterioArticoli {
    static var articoli: StatoArticoli {
        StatoArticoli(tipo: .articoli, criteri: CriterioArticoli.perArticoli, ordineIniziale: .articoli)
    }

    static var storico: StatoArticoli {
        StatoArticoli(tipo: .storico, criteri: CriterioArticoli.perStorico, ordineIniziale: .storico)
    }

    static var struttura: StatoArticoli {
        StatoArticoli(tipo: .struttura, criteri: CriterioArticoli.perStruttura, ordineIniziale: .articoli)
    }
}

extension StatoElenco where Filtro == FiltroProdotti, Criterio == CriterioProdotti {
    static var prodotti: StatoProdotti {
        StatoProdotti(tipo: .prodotti, criteri: CriterioProdotti.allCases, ordineIniziale: .prodotti)
    }
}

extension VistaSalvata {
    /// Il filtro salvato; se manca o non si legge, il filtro vuoto.
    func filtro<Filtro: FiltroSalvabile>(_ tipo: Filtro.Type) -> Filtro {
        guard let filtroJSON, let filtro = try? JSONDecoder().decode(Filtro.self, from: filtroJSON) else {
            return Filtro()
        }
        return filtro
    }

    /// L'ordine salvato; se il criterio non vale per questo elenco, quello iniziale.
    func ordine<Criterio: CriterioOrdinamento>(criteri: [Criterio], iniziale: Ordine<Criterio>) -> Ordine<Criterio> {
        guard let criterioRaw, let criterio = Criterio(rawValue: criterioRaw), criteri.contains(criterio) else {
            return iniziale
        }
        var ordine = Ordine(criterio)
        ordine.crescente = crescente
        return ordine
    }

    /// Salva nella vista filtro e ordine.
    func imposta<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento>(filtro: Filtro, ordine: Ordine<Criterio>) {
        filtroJSON = try? JSONEncoder().encode(filtro)
        criterioRaw = ordine.criterio.rawValue
        crescente = ordine.crescente
    }
}

extension Dispensa {
    /// Le viste salvate di un elenco, in ordine alfabetico.
    func viste(per tipo: TipoElenco) -> [VistaSalvata] {
        (viste ?? [])
            .filter { $0.tipo == tipo && !$0.isDeleted }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }
}

extension ModelContext {
    /// Salva filtro e ordine di un elenco come nuova vista. Il nome dev'essere unico tra le viste di quell'elenco.
    @discardableResult
    func creaVista<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento>(
        nome: String,
        stato: StatoElenco<Filtro, Criterio>,
        in dispensa: Dispensa
    ) throws -> VistaSalvata {
        let nome = try nomeVistaValido(nome, tipo: stato.tipo, in: dispensa, escludendo: nil)
        let vista = VistaSalvata(nome: nome, tipo: stato.tipo)
        insert(vista)
        vista.dispensa = dispensa
        vista.imposta(filtro: stato.filtro, ordine: stato.ordine)
        return vista
    }

    /// Sostituisce filtro e ordine della vista con quelli attuali dell'elenco.
    func aggiornaVista<Filtro: FiltroSalvabile, Criterio: CriterioOrdinamento>(
        _ vista: VistaSalvata,
        con stato: StatoElenco<Filtro, Criterio>
    ) {
        vista.imposta(filtro: stato.filtro, ordine: stato.ordine)
    }

    func rinominaVista(_ vista: VistaSalvata, nome: String) throws {
        guard let dispensa = vista.dispensa, let tipo = vista.tipo else {
            let nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nome.isEmpty else { throw ErroreGestioneViste.nomeVuoto }
            vista.nome = nome
            return
        }
        vista.nome = try nomeVistaValido(nome, tipo: tipo, in: dispensa, escludendo: vista)
    }

    /// Elimina una vista; non tocca nient'altro.
    func eliminaVista(_ vista: VistaSalvata) {
        delete(vista)
    }

    private func nomeVistaValido(
        _ nome: String,
        tipo: TipoElenco,
        in dispensa: Dispensa,
        escludendo esclusa: VistaSalvata?
    ) throws -> String {
        let nome = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nome.isEmpty else { throw ErroreGestioneViste.nomeVuoto }
        let duplicato = dispensa.viste(per: tipo).contains {
            $0 !== esclusa && $0.nome.compare(nome, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        guard !duplicato else { throw ErroreGestioneViste.nomeDuplicato }
        return nome
    }
}
