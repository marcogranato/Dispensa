//
//  DispensaUITests.swift
//  DispensaUITests
//
//  Created by Marco Granato on 07/11/2026.
//

import XCTest

final class DispensaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Avvia l'app con un database vuoto in memoria, crea la dispensa "Casa" e la apre.
    @MainActor
    private func avviaConDispensa() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--in-memoria"]
        app.launch()

        app.buttons["Crea la tua prima dispensa"].tap()
        scrivi("Casa", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        app.buttons["Casa"].tap()
        return app
    }

    /// I campi con un testo di esempio non sono identificati dall'etichetta: si usa il primo campo.
    @MainActor
    private func scrivi(_ testo: String, nelPrimoCampoDi app: XCUIApplication) {
        let campo = app.textFields.firstMatch
        XCTAssertTrue(campo.waitForExistence(timeout: 5))
        campo.tap()
        campo.typeText(testo)
    }

    @MainActor
    private func allegaScreenshot(_ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    /// Crea una struttura e ne apre il dettaglio.
    @MainActor
    func testCreaDispensaEStruttura() throws {
        let app = avviaConDispensa()

        app.buttons["Aggiungi una struttura"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()

        // Senza nome, la struttura prende il nome del tipo predefinito.
        let struttura = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Frigorifero'")).firstMatch
        XCTAssertTrue(struttura.waitForExistence(timeout: 5))
        struttura.tap()

        XCTAssertTrue(app.navigationBars["Frigorifero"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Tipo"].exists)
        XCTAssertTrue(app.staticTexts["Ubicazione, Nessuna"].exists)
        allegaScreenshot(app)
    }

    /// Aggiunge due confezioni di un nuovo prodotto in una struttura.
    @MainActor
    func testAggiungiArticoli() throws {
        let app = avviaConDispensa()

        app.buttons["Aggiungi una struttura"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()
        let struttura = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Frigorifero'")).firstMatch
        XCTAssertTrue(struttura.waitForExistence(timeout: 5))
        struttura.tap()

        app.buttons["Aggiungi articolo"].tap()
        scrivi("Latte", nelPrimoCampoDi: app)
        XCTAssertTrue(app.staticTexts["Verrà creato il nuovo prodotto «Latte»."].exists)
        app.steppers.matching(NSPredicate(format: "label BEGINSWITH 'Confezioni da aggiungere'")).firstMatch.buttons.element(boundBy: 1).tap()
        allegaScreenshot(app)
        app.buttons["Salva"].tap()

        XCTAssertTrue(app.staticTexts["Presenti, 2"].waitForExistence(timeout: 5))
        allegaScreenshot(app)
    }

    /// Crea un prodotto dal menu "Altro" e lo ritrova nel catalogo.
    @MainActor
    func testCreaProdotto() throws {
        let app = avviaConDispensa()

        app.buttons["Altro"].tap()
        app.buttons["Prodotti"].tap()
        app.buttons["Aggiungi un prodotto"].tap()
        scrivi("Pasta", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        XCTAssertTrue(app.staticTexts["Pasta"].waitForExistence(timeout: 5))
        allegaScreenshot(app)
    }
}
