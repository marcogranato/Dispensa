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

    /// Crea una dispensa e una struttura, poi apre il dettaglio della struttura.
    @MainActor
    func testCreaDispensaEStruttura() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--in-memoria"]
        app.launch()

        app.buttons["Crea la tua prima dispensa"].tap()
        let campoNome = app.textFields.firstMatch
        XCTAssertTrue(campoNome.waitForExistence(timeout: 5))
        campoNome.tap()
        campoNome.typeText("Casa")
        app.buttons["Salva"].tap()

        app.buttons["Casa"].tap()

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

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
