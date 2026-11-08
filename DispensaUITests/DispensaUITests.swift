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

    /// Crea una struttura senza nome (prende il nome del tipo, "Frigorifero") e ne apre il dettaglio.
    @MainActor
    private func creaEApriStruttura(_ app: XCUIApplication) {
        app.buttons["Aggiungi una struttura"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()
        tocca(rigaCheIniziaCon: "Frigorifero", in: app)
        XCTAssertTrue(app.navigationBars["Frigorifero"].waitForExistence(timeout: 5))
    }

    /// Le righe sono pulsanti con un'etichetta composta (es. "Frigorifero, 0"): si cerca l'inizio.
    @MainActor
    private func tocca(rigaCheIniziaCon testo: String, in app: XCUIApplication) {
        let riga = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", testo)).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 5))
        riga.tap()
    }

    /// Crea una struttura e ne apre il dettaglio.
    @MainActor
    func testCreaDispensaEStruttura() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        XCTAssertTrue(app.staticTexts["Tipo"].exists)
        XCTAssertTrue(app.staticTexts["Ubicazione, Nessuna"].exists)
        allegaScreenshot(app)
    }

    /// Aggiunge due confezioni di un nuovo prodotto in una struttura.
    @MainActor
    func testAggiungiArticoli() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        app.buttons["Aggiungi articolo"].tap()
        scrivi("Latte", nelPrimoCampoDi: app)
        XCTAssertTrue(app.staticTexts["Verrà creato il nuovo prodotto «Latte»."].exists)
        aumenta("Confezioni da aggiungere", di: 1, in: app)
        app.buttons["Salva"].tap()

        XCTAssertTrue(app.staticTexts["Articoli presenti: 2"].waitForExistence(timeout: 5))
        allegaScreenshot(app)
    }

    /// Aggiunge un articolo da 6 parti, ne preleva una e butta il resto: l'articolo esce dalla dispensa.
    @MainActor
    func testPrelevaEButta() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        app.buttons["Aggiungi articolo"].tap()
        scrivi("Biscotti", nelPrimoCampoDi: app)
        aumenta("Parti per confezione", di: 5, in: app)
        app.buttons["Salva"].tap()

        tocca(rigaCheIniziaCon: "Biscotti", in: app)
        XCTAssertTrue(app.staticTexts["Parti, 6 di 6"].waitForExistence(timeout: 5))

        app.buttons["Preleva…"].tap()
        app.buttons["Preleva"].tap()
        XCTAssertTrue(app.staticTexts["Parti, 5 di 6"].waitForExistence(timeout: 5))
        allegaScreenshot(app)

        app.buttons["Butta…"].tap()
        XCTAssertTrue(app.staticTexts["La confezione sarà vuota e passerà nello storico."].waitForExistence(timeout: 5))
        app.buttons["Butta"].tap()

        // L'articolo è uscito: si torna alla struttura, ora vuota.
        XCTAssertTrue(app.staticTexts["Articoli presenti: 0"].waitForExistence(timeout: 5))
        allegaScreenshot(app)
    }

    /// Preme `volte` il "+" dello stepper che inizia con `etichetta`.
    @MainActor
    private func aumenta(_ etichetta: String, di volte: Int, in app: XCUIApplication) {
        let stepper = app.steppers.matching(NSPredicate(format: "label BEGINSWITH %@", etichetta)).firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        for _ in 0..<volte {
            stepper.buttons.element(boundBy: 1).tap()
        }
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
