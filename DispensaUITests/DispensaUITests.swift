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

    /// Avvia l'app con un database vuoto in memoria e crea la dispensa "Casa", che si apre sulla scheda Strutture.
    @MainActor
    private func avviaConDispensa() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--in-memoria"]
        app.launch()

        app.buttons["Crea la tua prima dispensa"].tap()
        scrivi("Casa", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.buttons["Aggiungi una struttura"].waitForExistence(timeout: 5))
        return app
    }

    /// Apre una scheda della barra in basso (Strutture, Articoli, Prodotti, Storico).
    @MainActor
    private func apri(scheda: String, in app: XCUIApplication) {
        let pulsante = app.tabBars.buttons[scheda]
        XCTAssertTrue(pulsante.waitForExistence(timeout: 5))
        pulsante.tap()
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

    /// Due articoli con lo stesso nome e marche diverse diventano due prodotti distinti.
    @MainActor
    func testProdottiDiMarcheDiverse() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        for marca in ["Barilla", "De Cecco"] {
            app.buttons["Aggiungi articolo"].tap()
            scrivi("Penne", nelPrimoCampoDi: app)
            scrivi(marca, nelCampoConEsempio: "Marca (facoltativa)", in: app)
            XCTAssertTrue(app.staticTexts["Verrà creato il nuovo prodotto «Penne» (\(marca))."].waitForExistence(timeout: 5))
            app.buttons["Salva"].tap()
        }
        XCTAssertTrue(app.staticTexts["Articoli presenti: 2"].waitForExistence(timeout: 5))

        apri(scheda: "Prodotti", in: app)
        let righe = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Penne"))
        XCTAssertTrue(righe.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(righe.count, 2)
        allegaScreenshot(app)
    }

    /// Nella scheda Articoli il filtro per struttura lascia solo gli articoli di quella struttura; "Azzera" li riporta tutti.
    @MainActor
    func testFiltri() throws {
        let app = avviaConDispensa()

        // Frigorifero con il latte, Cantina con il vino.
        creaEApriStruttura(app)
        app.buttons["Aggiungi articolo"].tap()
        scrivi("Latte", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.staticTexts["Articoli presenti: 1"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].tap()

        app.buttons["Nuova struttura"].tap()
        scrivi("Cantina", nelCampoConEsempio: "Frigorifero", in: app)
        app.buttons["Salva"].tap()
        tocca(rigaCheIniziaCon: "Cantina", in: app)
        app.buttons["Aggiungi articolo"].tap()
        scrivi("Vino", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.staticTexts["Articoli presenti: 1"].waitForExistence(timeout: 5))

        apri(scheda: "Articoli", in: app)
        let latte = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Latte")).firstMatch
        let vino = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Vino")).firstMatch
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        XCTAssertTrue(vino.exists)

        app.buttons["Filtri"].tap()
        let cantina = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Cantina")).firstMatch
        XCTAssertTrue(cantina.waitForExistence(timeout: 5))
        cantina.tap()
        app.buttons["Fine"].tap()

        XCTAssertTrue(app.staticTexts["Filtri attivi: 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(vino.exists)
        XCTAssertFalse(latte.exists)
        allegaScreenshot(app)

        app.buttons["Azzera"].tap()
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        XCTAssertTrue(vino.exists)
    }

    /// Ordina gli articoli per nome dalla Z alla A: il vino passa sopra il latte.
    @MainActor
    func testOrdinamento() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)
        for nome in ["Latte", "Vino"] {
            app.buttons["Aggiungi articolo"].tap()
            scrivi(nome, nelPrimoCampoDi: app)
            app.buttons["Salva"].tap()
        }
        XCTAssertTrue(app.staticTexts["Articoli presenti: 2"].waitForExistence(timeout: 5))

        apri(scheda: "Articoli", in: app)
        let latte = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Latte")).firstMatch
        let vino = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Vino")).firstMatch
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        // Senza scadenza vale l'ordine per nome: prima il latte.
        XCTAssertLessThan(latte.frame.minY, vino.frame.minY)

        app.buttons["Ordina"].tap()
        app.buttons["Nome"].tap()
        app.buttons["Ordina"].tap()
        let zA = app.buttons["Z → A"]
        XCTAssertTrue(zA.waitForExistence(timeout: 5))
        zA.tap()

        XCTAssertTrue(vino.waitForExistence(timeout: 5))
        XCTAssertLessThan(vino.frame.minY, latte.frame.minY)
        allegaScreenshot(app)
    }

    /// Ricerca nella scheda della struttura e filtro "Senza articoli" nella scheda Prodotti.
    @MainActor
    func testFiltriProdottiERicercaInStruttura() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)
        for nome in ["Latte", "Vino"] {
            app.buttons["Aggiungi articolo"].tap()
            scrivi(nome, nelPrimoCampoDi: app)
            app.buttons["Salva"].tap()
        }
        XCTAssertTrue(app.staticTexts["Articoli presenti: 2"].waitForExistence(timeout: 5))

        // Ricerca dentro la struttura: su iPhone il campo compare tirando giù l'elenco.
        let campoRicerca = app.searchFields.firstMatch
        if !campoRicerca.exists {
            app.collectionViews.firstMatch.swipeDown()
        }
        XCTAssertTrue(campoRicerca.waitForExistence(timeout: 5))
        campoRicerca.tap()
        campoRicerca.typeText("vino")
        XCTAssertTrue(app.staticTexts["Articoli presenti: 1 di 2"].waitForExistence(timeout: 5))
        let latteInStruttura = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Latte")).firstMatch
        XCTAssertFalse(latteInStruttura.exists)
        allegaScreenshot(app)

        // Chiude la ricerca: la tastiera coprirebbe la barra delle schede.
        app.buttons["Chiudi"].tap()

        // Un prodotto senza articoli.
        apri(scheda: "Prodotti", in: app)
        let nuovoProdotto = app.buttons["Nuovo prodotto"]
        XCTAssertTrue(nuovoProdotto.waitForExistence(timeout: 5))
        nuovoProdotto.tap()
        scrivi("Sale", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        let latte = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Latte")).firstMatch
        let sale = app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Sale")).firstMatch
        XCTAssertTrue(sale.waitForExistence(timeout: 5))
        XCTAssertTrue(latte.exists)

        app.buttons["Filtri"].tap()
        let senzaArticoli = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Senza articoli")).firstMatch
        XCTAssertTrue(senzaArticoli.waitForExistence(timeout: 5))
        senzaArticoli.tap()
        app.buttons["Fine"].tap()

        XCTAssertTrue(app.staticTexts["Filtri attivi: 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(sale.exists)
        XCTAssertFalse(latte.exists)
        allegaScreenshot(app)

        app.buttons["Azzera"].tap()
        XCTAssertTrue(latte.waitForExistence(timeout: 5))
        XCTAssertTrue(sale.exists)
    }

    /// Scrive in un campo trovato dal suo testo di esempio (placeholder).
    @MainActor
    private func scrivi(_ testo: String, nelCampoConEsempio esempio: String, in app: XCUIApplication) {
        let campo = app.textFields.matching(NSPredicate(format: "placeholderValue == %@", esempio)).firstMatch
        XCTAssertTrue(campo.waitForExistence(timeout: 5))
        campo.tap()
        campo.typeText(testo)
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

    /// Butta un articolo, lo ritrova nello storico con il motivo e lo rimette in dispensa.
    @MainActor
    func testStorico() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        app.buttons["Aggiungi articolo"].tap()
        scrivi("Yogurt", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        tocca(rigaCheIniziaCon: "Yogurt", in: app)
        app.buttons["Butta…"].tap()
        app.buttons["Butta"].tap()
        XCTAssertTrue(app.staticTexts["Articoli presenti: 0"].waitForExistence(timeout: 5))

        apri(scheda: "Storico", in: app)

        let esito = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Buttato (Avariato)'")).firstMatch
        XCTAssertTrue(esito.waitForExistence(timeout: 5))
        allegaScreenshot(app)

        app.cells.containing(.staticText, identifier: "Yogurt").firstMatch.swipeRight()
        app.buttons["Rimetti in dispensa"].tap()
        XCTAssertTrue(app.staticTexts["Storico vuoto"].waitForExistence(timeout: 5))

        // La scheda Strutture è rimasta sul frigorifero, dove l'articolo è tornato.
        apri(scheda: "Strutture", in: app)
        XCTAssertTrue(app.staticTexts["Articoli presenti: 1"].waitForExistence(timeout: 5))
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

    /// Crea un prodotto dalla scheda Prodotti, ne apre la scheda e da lì la modifica.
    @MainActor
    func testCreaProdotto() throws {
        let app = avviaConDispensa()

        apri(scheda: "Prodotti", in: app)
        app.buttons["Aggiungi un prodotto"].tap()
        scrivi("Pasta", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        // Il click sulla riga apre la scheda in sola lettura, non la modifica.
        tocca(rigaCheIniziaCon: "Pasta", in: app)
        XCTAssertTrue(app.navigationBars["Pasta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Articoli presenti: 0"].exists)
        allegaScreenshot(app)

        app.navigationBars["Pasta"].buttons["Modifica"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
    }

    /// Le etichette si aprono dalla scheda Prodotti, si creano e si danno a un prodotto dal suo modulo.
    @MainActor
    func testEtichette() throws {
        let app = avviaConDispensa()

        apri(scheda: "Prodotti", in: app)
        app.buttons["Categorie ed etichette"].tap()
        app.buttons["Etichette"].tap()
        let aggiungi = app.buttons["Aggiungi un'etichetta"]
        XCTAssertTrue(aggiungi.waitForExistence(timeout: 5))
        aggiungi.tap()
        // Il cancelletto e gli spazi vengono tolti dal nome.
        scrivi("#cola zione", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        tocca(rigaCheIniziaCon: "#colazione", in: app)
        XCTAssertTrue(app.navigationBars["#colazione"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Prodotti: 0"].exists)
        app.navigationBars.buttons["BackButton"].tap()
        app.navigationBars.buttons["BackButton"].tap()

        // Nuovo prodotto con l'etichetta, scelta dall'elenco con le spunte.
        let aggiungiProdotto = app.buttons["Aggiungi un prodotto"]
        XCTAssertTrue(aggiungiProdotto.waitForExistence(timeout: 5))
        aggiungiProdotto.tap()
        scrivi("Biscotti", nelPrimoCampoDi: app)
        app.buttons["Aggiungi etichette"].tap()
        let riga = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "#colazione")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 5))
        riga.tap()
        app.buttons["Fine"].tap()
        XCTAssertTrue(app.buttons["Cambia etichette"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()

        tocca(rigaCheIniziaCon: "Biscotti", in: app)
        XCTAssertTrue(app.navigationBars["Biscotti"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["#colazione"].exists)
        allegaScreenshot(app)

        // Nella scheda Prodotti la ricerca con "#" trova il prodotto dall'etichetta.
        app.navigationBars.buttons["BackButton"].tap()
        let campoRicerca = app.searchFields.firstMatch
        XCTAssertTrue(campoRicerca.waitForExistence(timeout: 5))
        campoRicerca.tap()
        campoRicerca.typeText("#colaz")
        XCTAssertTrue(app.cells.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Biscotti")).firstMatch.waitForExistence(timeout: 5))
    }

    /// Le categorie si aprono dalla scheda Prodotti; il tocco su una categoria apre la sua scheda.
    @MainActor
    func testCategorie() throws {
        let app = avviaConDispensa()

        apri(scheda: "Prodotti", in: app)
        app.buttons["Categorie ed etichette"].tap()
        app.buttons["Categorie"].tap()
        let aggiungi = app.buttons["Aggiungi una categoria"]
        XCTAssertTrue(aggiungi.waitForExistence(timeout: 5))
        aggiungi.tap()
        scrivi("Pasta", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        tocca(rigaCheIniziaCon: "Pasta", in: app)
        XCTAssertTrue(app.navigationBars["Pasta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Prodotti: 0"].exists)
        XCTAssertTrue(app.buttons["Elimina categoria"].exists)
        allegaScreenshot(app)

        // Una categoria vuota si elimina senza conferma e si torna all'elenco.
        app.buttons["Elimina categoria"].tap()
        XCTAssertTrue(app.buttons["Aggiungi una categoria"].waitForExistence(timeout: 5))
    }

    /// Le ubicazioni si aprono dalla scheda Strutture; la scheda di un'ubicazione mostra le sue strutture
    /// e ne crea di nuove già collegate.
    @MainActor
    func testUbicazioni() throws {
        let app = avviaConDispensa()

        let ubicazioni = app.buttons["Ubicazioni"]
        XCTAssertTrue(ubicazioni.waitForExistence(timeout: 5))
        ubicazioni.tap()
        let suggerimento = app.buttons["Cucina"]
        XCTAssertTrue(suggerimento.waitForExistence(timeout: 5))
        suggerimento.tap()

        tocca(rigaCheIniziaCon: "Cucina", in: app)
        XCTAssertTrue(app.navigationBars["Cucina"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Strutture: 0"].exists)

        app.buttons["Aggiungi struttura"].tap()
        XCTAssertTrue(app.buttons["Salva"].waitForExistence(timeout: 5))
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.staticTexts["Strutture: 1"].waitForExistence(timeout: 5))
        allegaScreenshot(app)

        // Con una struttura collegata l'eliminazione chiede conferma; poi si torna all'elenco.
        app.buttons["Elimina ubicazione"].tap()
        let conferma = app.buttons["Elimina"]
        XCTAssertTrue(conferma.waitForExistence(timeout: 5))
        conferma.tap()
        XCTAssertTrue(app.navigationBars["Ubicazioni"].waitForExistence(timeout: 5))

        // La struttura resta, senza ubicazione.
        app.buttons["BackButton"].tap()
        XCTAssertTrue(app.staticTexts["Senza ubicazione"].waitForExistence(timeout: 5))
    }

    /// Un prodotto senza articoli si elimina dalla sua scheda, senza conferma, e si torna all'elenco.
    @MainActor
    func testEliminaProdottoDallaScheda() throws {
        let app = avviaConDispensa()

        apri(scheda: "Prodotti", in: app)
        app.buttons["Aggiungi un prodotto"].tap()
        scrivi("Pasta", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()

        tocca(rigaCheIniziaCon: "Pasta", in: app)
        let elimina = app.buttons["Elimina prodotto"]
        XCTAssertTrue(elimina.waitForExistence(timeout: 5))
        elimina.tap()

        XCTAssertTrue(app.buttons["Aggiungi un prodotto"].waitForExistence(timeout: 5))
    }

    /// Un articolo aggiunto in una struttura compare nella scheda Articoli, con la sua struttura, e si apre.
    @MainActor
    func testElencoArticoli() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)

        app.buttons["Aggiungi articolo"].tap()
        scrivi("Latte", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.staticTexts["Articoli presenti: 1"].waitForExistence(timeout: 5))

        apri(scheda: "Articoli", in: app)
        XCTAssertTrue(app.staticTexts["Frigorifero"].waitForExistence(timeout: 5))
        allegaScreenshot(app)
        tocca(rigaCheIniziaCon: "Latte", in: app)
        XCTAssertTrue(app.navigationBars["Latte"].waitForExistence(timeout: 5))
    }

    /// Crea una seconda dispensa dal menu nel titolo: si apre vuota; poi si torna a "Casa".
    @MainActor
    func testCambiaDispensa() throws {
        let app = avviaConDispensa()
        creaEApriStruttura(app)
        app.navigationBars.buttons["BackButton"].tap()

        app.buttons["Dispensa: Casa"].tap()
        app.buttons["Nuova dispensa…"].tap()
        scrivi("Mare", nelPrimoCampoDi: app)
        app.buttons["Salva"].tap()
        XCTAssertTrue(app.buttons["Aggiungi una struttura"].waitForExistence(timeout: 5))
        allegaScreenshot(app)

        app.buttons["Dispensa: Mare"].tap()
        app.buttons["Casa"].tap()
        tocca(rigaCheIniziaCon: "Frigorifero", in: app)
        XCTAssertTrue(app.navigationBars["Frigorifero"].waitForExistence(timeout: 5))
    }
}
