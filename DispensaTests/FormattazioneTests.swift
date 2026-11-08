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
}
