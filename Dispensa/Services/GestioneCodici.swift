//
//  GestioneCodici.swift
//  Dispensa
//

import Foundation
import SwiftData

/// Errori nella gestione dei codici a barre.
enum ErroreGestioneCodici: LocalizedError, Equatable {
    /// Il codice appartiene già a un altro prodotto della dispensa (nome e marca).
    case codiceGiaUsato(codice: String, prodotto: String)

    var errorDescription: String? {
        switch self {
        case let .codiceGiaUsato(codice, prodotto):
            String(localized: "Il codice \(codice) è già del prodotto «\(prodotto)».")
        }
    }
}

/// Dove mettere un codice appena letto con lo scanner, tra i campi del modulo.
enum PosizioneCodice: Equatable {
    /// Il prodotto ha già questo codice, in quel campo: nessun doppione.
    case giaPresente(Int)
    /// Il primo campo vuoto.
    case campoVuoto(Int)
    /// Un campo nuovo in fondo.
    case inFondo
}

enum Codici {
    /// Dove va il codice `letto` tra i campi scritti nel modulo.
    static func posizione(del letto: String, in campi: [String]) -> PosizioneCodice {
        let letto = letto.trimmingCharacters(in: .whitespacesAndNewlines)
        let puliti = campi.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let indice = puliti.firstIndex(of: letto) {
            return .giaPresente(indice)
        }
        if let indice = puliti.firstIndex(where: \.isEmpty) {
            return .campoVuoto(indice)
        }
        return .inFondo
    }

    /// Codici ripuliti dagli spazi, senza vuoti e senza doppioni, nell'ordine in cui sono scritti.
    static func puliti(_ codici: [String]) -> [String] {
        var visti = Set<String>()
        return codici
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && visti.insert($0).inserted }
    }
}

extension Prodotto {
    /// I codici del prodotto, dal primo inserito.
    var codiciOrdinati: [String] {
        (codici ?? [])
            .filter { !$0.isDeleted }
            .sorted { $0.dataCreazione < $1.dataCreazione }
            .map(\.codice)
    }

    /// Vero se uno dei codici del prodotto è esattamente `codice`.
    func haCodice(_ codice: String) -> Bool {
        (codici ?? []).contains { !$0.isDeleted && $0.codice == codice }
    }
}

extension Dispensa {
    /// Il prodotto con questo codice, se c'è.
    func prodotto(conCodice codice: String) -> Prodotto? {
        let codice = codice.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codice.isEmpty else { return nil }
        return (prodotti ?? []).first { !$0.isDeleted && $0.haCodice(codice) }
    }

    /// Il primo codice dell'elenco che appartiene già a un prodotto diverso da `prodotto`, con quel prodotto.
    func codiceGiaUsato(tra codici: [String], escluso prodotto: Prodotto?) -> (codice: String, prodotto: Prodotto)? {
        for codice in Codici.puliti(codici) {
            if let altro = self.prodotto(conCodice: codice), altro !== prodotto {
                return (codice, altro)
            }
        }
        return nil
    }
}

extension ModelContext {
    /// Sostituisce i codici del prodotto. Si ferma (senza cambiare nulla) se un codice è di un altro prodotto.
    func impostaCodici(_ codici: [String], a prodotto: Prodotto) throws {
        let nuovi = Codici.puliti(codici)
        if let dispensa = prodotto.dispensa, let usato = dispensa.codiceGiaUsato(tra: nuovi, escluso: prodotto) {
            throw ErroreGestioneCodici.codiceGiaUsato(codice: usato.codice, prodotto: usato.prodotto.nomeConMarca)
        }
        let esistenti = (prodotto.codici ?? []).filter { !$0.isDeleted }
        for vecchio in esistenti where !nuovi.contains(vecchio.codice) {
            delete(vecchio)
        }
        let rimasti = Set(esistenti.map(\.codice))
        for (posizione, codice) in nuovi.enumerated() where !rimasti.contains(codice) {
            let nuovo = CodiceBarre(codice: codice)
            // Così l'ordine resta quello scritto anche per codici aggiunti insieme.
            nuovo.dataCreazione = Date.now.addingTimeInterval(Double(posizione) / 1000)
            insert(nuovo)
            nuovo.prodotto = prodotto
        }
    }

    /// Collega un codice letto al prodotto, ma solo se è libero: se è già suo o di un altro prodotto non cambia nulla.
    /// Restituisce vero se il codice è stato aggiunto.
    @discardableResult
    func aggiungiCodice(_ codice: String, a prodotto: Prodotto) -> Bool {
        let codice = codice.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codice.isEmpty, !prodotto.haCodice(codice) else { return false }
        if let dispensa = prodotto.dispensa, dispensa.prodotto(conCodice: codice) != nil { return false }
        let nuovo = CodiceBarre(codice: codice)
        insert(nuovo)
        nuovo.prodotto = prodotto
        return true
    }

    /// Porta il vecchio campo `codiceBarre` dei prodotti nei codici multipli e lo svuota.
    /// Si può chiamare a ogni avvio: i prodotti già sistemati non cambiano.
    func spostaCodiciVecchi() {
        let descrittore = FetchDescriptor<Prodotto>(predicate: #Predicate { $0.codiceBarre != nil })
        guard let prodotti = try? fetch(descrittore), !prodotti.isEmpty else { return }
        for prodotto in prodotti {
            if let vecchio = prodotto.codiceBarre?.trimmingCharacters(in: .whitespacesAndNewlines),
               !vecchio.isEmpty, !prodotto.haCodice(vecchio) {
                let codice = CodiceBarre(codice: vecchio)
                insert(codice)
                codice.prodotto = prodotto
            }
            prodotto.codiceBarre = nil
        }
        try? save()
    }
}
