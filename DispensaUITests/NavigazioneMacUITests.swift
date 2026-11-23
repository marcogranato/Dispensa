//
//  NavigazioneMacUITests.swift
//  DispensaUITests
//

#if os(macOS)
import XCTest

/// Sul Mac le righe degli elenchi devono aprire il dettaglio anche quando sono rimaste selezionate:
/// dopo un cambio di scheda, dopo Indietro, dopo una selezione nello storico e dopo una modifica.
/// Gira solo con destinazione Mac (`-destination 'platform=macOS'`).
final class NavigazioneMacUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRigheSempreCliccabili() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--in-memoria"]
        app.launch()
        app.activate()

        // Dispensa, struttura e un articolo "Latte".
        app.buttons["Crea la tua prima dispensa"].click()
        let campo = app.textFields.firstMatch
        XCTAssertTrue(campo.waitForExistence(timeout: 10))
        campo.click()
        campo.typeText("Casa")
        app.buttons["Salva"].click()
        XCTAssertTrue(app.buttons["Aggiungi una struttura"].waitForExistence(timeout: 10))
        app.buttons["Aggiungi una struttura"].click()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 10))
        app.buttons["Salva"].click()
        let frigo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Frigorifero")).firstMatch
        XCTAssertTrue(frigo.waitForExistence(timeout: 10))
        frigo.click()
        app.buttons["Aggiungi articolo"].click()
        let nome = app.textFields.firstMatch
        XCTAssertTrue(nome.waitForExistence(timeout: 5))
        nome.click()
        nome.typeText("Latte")
        app.buttons["Salva"].click()

        // Scheda Articoli: apre il dettaglio del latte.
        app.outlines.staticTexts["Articoli"].click()
        let latte = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Latte")).firstMatch
        XCTAssertTrue(latte.waitForExistence(timeout: 5), "articoli: " + app.debugDescription)
        latte.click()
        XCTAssertTrue(app.buttons["Butta…"].waitForExistence(timeout: 5), "primo click: " + app.debugDescription)

        // Strutture e di nuovo Articoli, senza tornare indietro.
        app.outlines.staticTexts["Strutture"].click()
        app.outlines.staticTexts["Articoli"].click()
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        latte.click()
        XCTAssertTrue(app.buttons["Butta…"].waitForExistence(timeout: 5), "dopo cambio scheda: " + app.debugDescription)

        // Indietro e di nuovo click sulla stessa riga.
        app.toolbars.buttons["Indietro"].click()
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        latte.click()
        XCTAssertTrue(app.buttons["Butta…"].waitForExistence(timeout: 5), "dopo indietro: " + app.debugDescription)

        // Butta il latte, lo seleziona nello storico, poi apre una struttura.
        app.buttons["Butta…"].click()
        XCTAssertTrue(app.buttons["Butta"].waitForExistence(timeout: 5))
        app.buttons["Butta"].click()
        app.outlines.staticTexts["Storico"].click()
        let nelloStorico = app.staticTexts["Latte"].firstMatch
        XCTAssertTrue(nelloStorico.waitForExistence(timeout: 5), "storico: " + app.debugDescription)
        nelloStorico.click()
        app.outlines.staticTexts["Strutture"].click()
        XCTAssertTrue(frigo.waitForExistence(timeout: 5), "strutture: " + app.debugDescription)
        frigo.click()
        XCTAssertTrue(app.staticTexts["Tipo"].waitForExistence(timeout: 5), "dopo storico: " + app.debugDescription)

        // Modifica dal dettaglio, salva, indietro e di nuovo click.
        app.toolbars.buttons["Modifica"].click()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].click()
        app.toolbars.buttons["Indietro"].click()
        XCTAssertTrue(frigo.waitForExistence(timeout: 5))
        frigo.click()
        XCTAssertTrue(app.staticTexts["Tipo"].waitForExistence(timeout: 5), "dopo modifica: " + app.debugDescription)
    }
}
#endif
