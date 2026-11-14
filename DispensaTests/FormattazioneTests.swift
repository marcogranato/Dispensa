//
//  FormattazioneTests.swift
//  DispensaTests
//

import Testing
@testable import Dispensa

@MainActor
struct FormattazioneTests {
    @Test func quantita() {
        #expect(Formattazione.quantita(nil, unita: .grammi) == nil)
        #expect(Formattazione.quantita(150, unita: .grammi) == "150 g")
        #expect(Formattazione.quantita(2, unita: nil) == "2")
    }

    @Test func confezione() {
        #expect(Formattazione.confezione(parti: 6, quantitaPerParte: 150, unita: .grammi) == "6 × 150 g")
        #expect(Formattazione.confezione(parti: 6, quantitaPerParte: nil, unita: nil) == "6 parti")
        #expect(Formattazione.confezione(parti: 1, quantitaPerParte: 1, unita: .litri) == "1 l")
        #expect(Formattazione.confezione(parti: 1, quantitaPerParte: nil, unita: .litri) == nil)
    }

    @Test func confezioneEstesa() {
        #expect(Formattazione.confezioneEstesa(parti: 4, quantitaPerParte: 100, unita: .grammi, tipoParte: .pacchetto)
            == "4 pacchetti da 100 g (400 g)")
        #expect(Formattazione.confezioneEstesa(parti: 6, quantitaPerParte: 0.33, unita: .litri, tipoParte: nil)
            == "6 parti da 0,33 l (1,98 l)")
        #expect(Formattazione.confezioneEstesa(parti: 4, quantitaPerParte: nil, unita: nil, tipoParte: .bottiglia)
            == "4 bottiglie")
        #expect(Formattazione.confezioneEstesa(parti: 1, quantitaPerParte: 500, unita: .grammi, tipoParte: .pacchetto)
            == "500 g")
        #expect(Formattazione.confezioneEstesa(parti: 1, quantitaPerParte: nil, unita: nil, tipoParte: nil) == nil)
    }
}
