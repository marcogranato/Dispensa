//
//  TabelleiPadUITests.swift
//  DispensaUITests
//
//  Tabelle di iPad: si eseguono solo su un simulatore iPad, per esempio
//  xcodebuild ... -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' test -only-testing:DispensaUITests/TabelleiPadUITests
//

#if os(iOS)
import UIKit
import XCTest

final class TabelleiPadUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Le tabelle ci sono solo su iPad e Mac")
    }

    /// Nella scheda della struttura gli articoli sono in tabella: le colonne si mostrano e si nascondono
    /// dal menu Vista, e il tocco su una riga apre il dettaglio.
    @MainActor
    func testTabellaDellaStruttura() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--in-memoria"]
        app.launch()

        app.buttons["Crea la tua prima dispensa"].tap()
        scrivi("Casa", in: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.buttons["Aggiungi una struttura"].waitForExistence(timeout: 5))
        app.buttons["Aggiungi una struttura"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()
        let frigo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Frigorifero")).firstMatch
        XCTAssertTrue(frigo.waitForExistence(timeout: 5))
        frigo.tap()

        // Struttura vuota: il riquadro delle caratteristiche e il pulsante per aggiungere.
        XCTAssertTrue(app.staticTexts["Tipo"].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons["Aggiungi articolo"].tap()
        scrivi("Latte", in: app)
        app.buttons["Salva"].tap()

        let latte = app.staticTexts["Latte"].firstMatch
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        XCTAssertTrue(intestazione("Marca", in: app).exists, app.debugDescription)
        XCTAssertFalse(intestazione("Codice", in: app).exists)
        allegaScreenshot(app)

        // Colonne dal menu Vista: si mostra il codice e si nasconde la marca.
        scegliNelMenuVista("Colonne", "Codice", in: app)
        XCTAssertTrue(intestazione("Codice", in: app).waitForExistence(timeout: 5), app.debugDescription)
        scegliNelMenuVista("Colonne", "Marca", in: app)
        XCTAssertTrue(intestazione("Marca", in: app).waitForNonExistence(timeout: 5))
        allegaScreenshot(app)

        // "Ripristina colonne" torna a com'era.
        scegliNelMenuVista("Colonne", "Ripristina colonne", in: app)
        XCTAssertTrue(intestazione("Marca", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(intestazione("Codice", in: app).waitForNonExistence(timeout: 5))

        // Il tocco sulla riga apre il dettaglio dell'articolo.
        latte.tap()
        XCTAssertTrue(app.buttons["Butta…"].waitForExistence(timeout: 5), app.debugDescription)
    }

    // MARK: - Aiuti

    /// L'intestazione di una colonna della tabella: un pulsante se la colonna ordina, altrimenti un elemento generico.
    @MainActor
    private func intestazione(_ titolo: String, in app: XCUIApplication) -> XCUIElement {
        app.cells.firstMatch.descendants(matching: .any).matching(NSPredicate(format: "label == %@", titolo)).firstMatch
    }

    @MainActor
    private func scrivi(_ testo: String, in app: XCUIApplication) {
        let campo = app.textFields.firstMatch
        XCTAssertTrue(campo.waitForExistence(timeout: 5))
        campo.tap()
        campo.typeText(testo)
    }

    @MainActor
    private func scegliNelMenuVista(_ voci: String..., in app: XCUIApplication) {
        // In verticale le schede occupano la barra in alto e i pulsanti finiscono nel menu "…".
        if !app.buttons["Vista"].firstMatch.exists {
            let altro = app.buttons.matching(NSPredicate(format: "label IN %@", ["Altro", "More"])).firstMatch
            XCTAssertTrue(altro.waitForExistence(timeout: 5), app.debugDescription)
            altro.tap()
        }
        app.buttons["Vista"].firstMatch.tap()
        for voce in voci {
            let pulsante = app.buttons[voce].firstMatch
            XCTAssertTrue(pulsante.waitForExistence(timeout: 5), "Manca «\(voce)» nel menu Vista: " + app.debugDescription)
            pulsante.tap()
        }
    }

    @MainActor
    private func allegaScreenshot(_ app: XCUIApplication) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
#endif
