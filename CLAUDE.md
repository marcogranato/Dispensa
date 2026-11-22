# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Dispensa is a multiplatform SwiftUI + SwiftData app for iOS, iPadOS and macOS (versione minima iOS 26 / macOS 26). Requirements, glossary (Dispensa, Struttura, Prodotto, Articolo…), agreed decisions and development phases are in `docs/Requisiti.md` — read it before working on features.

## Regole di progetto

- **Lingua e spiegazioni:** l'utente è neofita di Xcode e Swift. Spiega in italiano, in breve, cosa fai e perché.
- **Nessun riferimento a Claude** nei messaggi di commit né nei commenti del codice (niente trailer `Co-Authored-By` o simili).
- **Piccoli passi:** dopo ogni modifica verifica che compili (vedi Commands). Quando un passo compila, proponi un commit con un messaggio chiaro; non fare commit senza conferma.
- **Non modificare senza chiedere:** `Dispensa.xcodeproj`, firma, capability, Bundle Identifier.
- **Nuovi file** in `Dispensa/Models`, `Dispensa/Views`, `Dispensa/Services`: Xcode li include automaticamente (vedi "Project file format").
- **Niente librerie esterne** senza chiedere: preferisci i framework Apple.
- **Interfaccia in italiano, predisposta per il multilingua:** usa stringhe localizzabili (`Text("...")`, `String(localized:)`, String Catalog), mai testo costruito in modo non traducibile.
- **Compatibilità CloudKit futura:** l'account Apple è gratuito, quindi niente CloudKit per ora, ma ogni `@Model` deve già rispettare i vincoli di CloudKit, così in futuro basterà attivare la sincronizzazione:
  - ogni proprietà opzionale o con valore di default;
  - ogni relazione opzionale;
  - niente `@Attribute(.unique)`.
- **Enum nei modelli:** salvarli come `String` grezza (es. `tipoRaw`) con una proprietà calcolata tipizzata, perché `#Predicate` non filtra bene sugli enum.
- **Dispositivi:** l'app deve funzionare da iPhone 13 in su. Versione minima iOS 26 / macOS 26: non usare API più recenti senza `if #available`.

## Stato del progetto

Dettagli e avanzamento in `docs/Requisiti.md` ("Stato dello sviluppo").

- **Fatto:** fasi 1, 2 e 3. Fase 1 (modello dati; dispense, ubicazioni, strutture) e fase 2 (prodotti e articoli: aggiunta, modifica, spostamento anche parziale, prelievo, scarto, storico). Della fase 3: ritocchi a modulo e riga dell'articolo; navigazione a quattro schede (Strutture, Articoli, Prodotti, Storico) con menu della dispensa nel titolo; elenco di tutti gli articoli; scheda del prodotto; navigazione affidabile sul Mac (con test UI dedicato). Punto 3 della fase 3 completo (**classificazione e dettagli dei prodotti**, `docs/Requisiti.md` aggiornato): albero delle categorie con scheda della categoria; modulo del prodotto a sezioni (categoria, descrizione, note, emoji, tipo di parte, totale e multipack calcolati); prodotti riconosciuti da nome + marca; categoria scelta anche nel modulo dell'articolo; Categorie e Ubicazioni aperte come schermate della pila (non più fogli), con scheda propria; emoji (`iconaEffettiva`) davanti al nome nelle righe di articoli, prodotti, storico e categorie (`IconaProdottoView`) e selettore di emoji a griglia nei moduli di categoria e prodotto (`SelettoreEmoji`); scheda Prodotti divisa per categoria principale ("Senza categoria" in fondo) con ricerca anche per categoria (`Services/RicercaProdotti.swift`). Punto 4 della fase 3 completo (**etichette, ricerca, filtri, ordinamento**): etichette con colore (`GestioneEtichette.swift`, schermata dalla scheda Prodotti, `SelettoreEtichette` nel modulo del prodotto); una sola ricerca per Articoli, Prodotti e Storico, "#" per cercare solo nelle etichette (`RicercaProdotti.swift`); filtri su strutture, categorie, etichette, stato e tutte le date in Articoli e Storico (`FiltriArticoli.swift`); ordinamento con criterio e verso in Articoli, Storico, Prodotti e scheda della struttura (`OrdinamentoElenchi.swift`). Filtri e ordine non si salvano.
- **Prossimo passo:** fase 4 — colonne configurabili, filtri salvati, vista predefinita per ogni elenco (vedi `docs/Requisiti.md`, "Visualizzazione e filtri"). Da pianificare con l'utente prima di iniziare.
- **Da provare a mano** (nessun test UI): spostamento parziale, swipe e menu contestuali, selezione multipla e "Rimetti in dispensa" nello storico, domanda alla disattivazione dello storico, tutta l'app su iPad; il selettore di emoji (foglio su iPhone, popover sul Mac, "Altra emoji" dalla tastiera); selettore delle etichette e palette dei colori; foglio dei filtri (date "Dal/Al") e menu "Ordina"; sul Mac la navigazione di Categorie e Ubicazioni (clic su righe, "+", Indietro, cambio di scheda), "Elimina prodotto", la scheda Prodotti divisa per categoria, etichette, filtri e menu "Ordina". I test UI del Mac (`NavigazioneMacUITests`) dopo il passo 5 non sono ancora stati eseguiti (il Mac non ha concesso l'"automation mode").
- **Piccolo difetto noto:** nel modulo dell'articolo, cambiando nome o marca la categoria scelta a mano viene sostituita da quella del prodotto omonimo.

## Decisioni prese

Le decisioni di prodotto complete sono in `docs/Requisiti.md` (sezioni "Decisioni prese"); le principali:

- Una dispensa alla volta, scelta dal menu nel titolo; l'app ricorda l'ultima aperta e al primo avvio non crea dati.
- Click su una riga = dettaglio in sola lettura; la modifica è sempre esplicita (eccezione: storico).
- Prelievo solo a parti intere; spostamento parziale divide la confezione in un nuovo articolo con le stesse date.
- Un nuovo nome nel modulo dell'articolo crea automaticamente il prodotto; più confezioni uguali diventano articoli separati.
- Un prodotto è identificato da **nome + marca** (Penne rigate Barilla e Penne rigate De Cecco sono due prodotti); un prodotto nuovo con lo stesso nome di uno esistente ne riprende emoji, e nel modulo dell'articolo propone categoria e tipo di parte.
- Categorie: un albero di massimo 3 livelli (categoria ▸ sottocategoria ▸ tipologia); il prodotto si collega al nodo più preciso; la categoria è facoltativa. Emoji su categorie e prodotti, ereditata dal nodo più vicino che ne ha una. Quantità totale e "multipack" sono calcolati, mai salvati. Un albero preimpostato è rimandato a una fase successiva (solo per DEBUG esiste "Aggiungi categorie di prova").
- `Etichetta` è solo un hashtag (niente tipo) con colore facoltativo; nome unico nella dispensa senza "#". La ricerca è la stessa in tutte le schede; un testo che inizia con "#" cerca solo nelle etichette. Filtri: dentro un gruppo basta una scelta, tra gruppi valgono tutte; date a giorni interi, estremi compresi. Ordinamento: date mancanti sempre in fondo. Filtri e ordine non si salvano (sarà la fase 4).
- "In scadenza" = 3 giorni o meno (diventerà un'impostazione nella fase 6); "scaduto" = data passata; sempre con icona oltre al colore.
- Eliminazioni: struttura → articoli presenti eliminati, storico conservato; dispensa → tutto; prodotto solo se senza articoli presenti (il suo storico va eliminato, con avviso); ubicazione → strutture senza ubicazione; categoria → sottocategorie eliminate, prodotti spostati alla categoria superiore (o senza categoria).
- Nessuna sincronizzazione finché l'account Apple è gratuito, ma modello già compatibile con CloudKit e con la `Dispensa` come radice della futura condivisione.
- Mac: `NavigationSplitView` costruito a mano e destinazioni di navigazione solo in `PilaDiNavigazione` (vedi Architecture).

## Commands

Single shared scheme: `Dispensa` (targets `Dispensa`, `DispensaTests`, `DispensaUITests`).

```sh
# Verifica di compilazione dopo ogni modifica
xcodebuild -scheme Dispensa -destination 'platform=iOS Simulator,name=iPhone 17' build

# In più, quando si toccano parti specifiche per Mac
xcodebuild -scheme Dispensa -destination 'platform=macOS' build

# Verifica sulla versione minima (simulatore iOS 26.1)
xcodebuild -scheme Dispensa -destination 'platform=iOS Simulator,OS=26.1,name=iPhone 17' build

# All tests (unit + UI; the UI tests take ~2 minutes)
xcodebuild -scheme Dispensa -destination 'platform=iOS Simulator,name=iPhone 17' test

# Unit tests only (fast) / a single Swift Testing test / a single UI test
xcodebuild ... test -only-testing:DispensaTests
xcodebuild ... test -only-testing:'DispensaTests/GestioneArticoliTests/prelevaRiduceLeParti()'
xcodebuild ... test -only-testing:DispensaUITests/DispensaUITests/testStorico

# Mac-only UI tests (NavigazioneMacUITests). Quit any Dispensa app launched from Xcode first,
# otherwise the test runner fails with "Failed to terminate com.marcogranato.Dispensa"
xcodebuild -scheme Dispensa -destination 'platform=macOS' test -only-testing:DispensaUITests/NavigazioneMacUITests

# Inspect a UI test run (screenshots, view hierarchy on failure)
xcodebuild ... -resultBundlePath <scratch>/ui.xcresult test -only-testing:DispensaUITests
xcrun xcresulttool export attachments --path <scratch>/ui.xcresult --output-path <scratch>/att   # manifest.json maps files to tests
```

There is no linter or formatter configured.

## Project file format

`Dispensa.xcodeproj/project.xcproj` is Xcode's JSON-style project format, not a classic `project.pbxproj`. Targets use **folder-based membership** (`"kind": "folder"` entries mapping `Dispensa/`, `DispensaTests/`, `DispensaUITests/` to their targets), so new source files dropped into those folders (including subfolders) are picked up automatically — no project-file edits are needed to add files.

## Architecture

- `DispensaApp.swift` builds the single persistent `ModelContainer` from `SchemaDispensa.schema`. Any new `@Model` type must be added to `SchemaDispensa.modelli` (`Dispensa/Models/SchemaDispensa.swift`), which is also used by previews and tests.
- Everything hangs off `Dispensa` (the future CloudKit share root): its relationships cascade. `Struttura → Articolo` and `Ubicazione → Struttura` are *nullify*, so the history (storico) survives deleting a struttura. `Categoria` is a tree (`genitore` / `sottocategorie`, max `Categoria.livelliMassimi` = 3 levels) with *nullify* towards subcategories and products; helpers `percorso`, `percorsoTestuale`, `livello`, `iconaEffettiva` (inherited emoji), `discendenti`, `prodottiCompresi`. `Prodotto` adds `categoria`, `icona`, `descrizione`, `note`, `tipoParte` (`TipoParte` enum, stored raw) and computed `nomeConMarca`, `quantitaTotale`, `isMultipack`, `iconaEffettiva`. Relationships are set after `context.insert(...)`, not in initializers.
- Article lifecycle: an `Articolo` is *attivo* while in a struttura; when its `partiRimaste` reach 0 (via `preleva`/`butta`) it becomes `consumato`/`buttato` with `dataUscita` (the storico), or is deleted if `Dispensa.storicoAbilitato` is false. `partiButtate` counts waste exactly; `StatoScadenza` (scaduto / in scadenza ≤ 3 days) is computed, never stored.
- Business rules live in `Services/` as `ModelContext` extensions and are unit-tested: `GestioneArticoli.swift` (preleva, butta, sposta with confezione split, rimettiInDispensa, storico cleanup, eliminaProdotto), `AggiuntaArticoli.swift` (`DatiArticolo`, `trovaOCreaProdotto(nominato:marca:…)`, `aggiungiArticoli`, product lookup by name + brand `Dispensa.prodotto(nominato:marca:)` / `prodottoOmonimo(nominato:)`), `GestioneStrutture.swift`, `GestioneCategorie.swift` (`creaCategoria`, `modificaCategoria` incl. moving with cycle/depth checks, `eliminaCategoria`), `GestioneEtichette.swift` (`creaEtichetta`, `modificaEtichetta`, `eliminaEtichetta`, name normalisation and duplicate check), `RicercaProdotti.swift` (`TestoRicerca`, `Prodotto/Articolo.corrisponde(a:)`, `Dispensa.gruppiDiProdotti(cercando:ordine:)`), `FiltriArticoli.swift` (`FiltroArticoli`, `IntervalloDate`), `OrdinamentoElenchi.swift` (generic `Ordine<Criterio>` with `CriterioArticoli` / `CriterioProdotti`). They validate input and throw `ErroreGestioneArticoli` / `ErroreGestioneCategorie` (`LocalizedError`s with Italian messages) instead of corrupting data; views show `error.localizedDescription` in an alert. Put new multi-model logic here, not in views.
- Views get persistence via `@Environment(\.modelContext)`; lists mostly read relationships of the current `Dispensa`/`Struttura` (e.g. `dispensa.articoliNelloStorico`, `struttura.articoliAttivi`) rather than `@Query`.
- UI entry point is `Views/RootView.swift`: four sections of the current dispensa — Strutture (`ElencoStruttureView`), Articoli (`ElencoArticoliView`, all active articles of every struttura), Prodotti (`ElencoProdottiView`), Storico (`StoricoView`). On iOS/iPadOS it is a `TabView` (`.sidebarAdaptable`); **on macOS it is a hand-built `NavigationSplitView`** (sidebar list + detail with `.id(scheda)`), because the Mac `TabView` sidebar shares one navigation stack between tabs and leaves rows stuck. Categorie (toolbar button in Prodotti) and Ubicazioni (toolbar button in Strutture) are screens pushed on the section's stack, not sheets.
- The current dispensa is chosen from `MenuDispensa` (title menu "Casa ▾", accessibility label "Dispensa: Casa"), which also creates / edits / deletes dispense. It is remembered in `@AppStorage("dispensaCorrente")` as `Dispensa.id`. Use `id`, never `persistentModelID`, for identity/`.id(...)`: a new object's `persistentModelID` changes on the first autosave and resets the navigation.
- Navigation: every section is wrapped in `PilaDiNavigazione` (`Views/PilaDiNavigazione.swift`), which declares **all** `navigationDestination`s once at the stack root (`Struttura`, `Articolo`, `Prodotto`, `Categoria`, `Etichetta`, `Ubicazione`, plus the list values `ElencoCategorie` / `ElencoEtichette` / `ElencoUbicazioni`). To push a screen from a toolbar button use `@Environment(\.apriNellaPila)` (`apri?(ElencoCategorie(dispensa:))`). Don't declare destinations inside individual screens (on the Mac they stop being visible and links fail or show a yellow triangle). List rows use `RigaNavigabile(valore:)`: a `NavigationLink` on iOS, a plain button that appends to the stack path on macOS (a selected Mac row otherwise ignores clicks).
- Lists: a click/tap opens a read-only detail (`DettaglioStrutturaView`, `DettaglioArticoloView`, `DettaglioProdottoView`, `DettaglioCategoriaView`, `DettaglioUbicazioneView`); editing is explicit ("Modifica"/"Rinomina" in the detail toolbar, context menu, swipe), and every action of a context menu must also be reachable from the detail (the Mac has no swipe). Exception: Storico (click selects, for multiple deletion).
- Article actions (preleva / butta / sposta / modifica / elimina) are shared via `MenuAzioniArticolo`, the `.azioniArticolo(_:daEliminare:)` modifier and the row `RigaArticoloConAzioni` (swipe + context menu, optional `mostraStruttura`) in `Views/AzioniArticolo.swift`; views only hold the two `@State` bindings. Same pattern (a `@State` request + a modifier shared by list and detail) for `.eliminazioneProdotto(_:)`, `.eliminazioneCategoria(_:)`, `.moduloCategoria(_:dispensa:)`, `.nomeUbicazione(_:dispensa:)` and `.eliminazioneUbicazione(_:)` (`Views/AzioniUbicazione.swift`), `.moduloEtichetta(_:dispensa:)` / `.eliminazioneEtichetta(_:)` (`Views/AzioniEtichetta.swift`). Lists with search/filters/sort hold `@State` values (`FiltroArticoli`, `OrdineArticoli`/`OrdineProdotti`) and use `.filtriArticoli(_:dispensa:perStorico:)` (`Views/FiltriArticoliView.swift`, with `RigaFiltriAttivi` / `NessunRisultatoConFiltri`) and `MenuOrdinamento(criteri:ordine:)` in the toolbar. Optional dates in forms use `RigaDataFacoltativa`; label chips `GettoneEtichettaView` / `GettoniEtichetteView`. Reusable rows: `RigaStrutturaView`, `RigaCategoriaView`, `RigaUbicazioneView`; category picker in `PickerCategoria.swift`.
- Views showing a single model must guard against it being deleted or leaving the pantry (`isDeleted`, `modelContext == nil`, `stato != .attivo`) — see `DettaglioArticoloView`, `DettaglioProdottoView`, `DettaglioCategoriaView`, `DettaglioUbicazioneView` (they `dismiss()` when their model is deleted).
- Forms (`*FormView`) edit local `@State` copies and write to the model only on "Salva"; `nil` model means "create new".
- Deletions of user data ask for confirmation via `confirmationDialog(presenting:)` only when something else is lost (contents, storico); empty items are deleted directly.
- Shared formatting ("6 × 150 g", "1,5 l") is in `Views/Formattazione.swift`; article rows and expiry badges in `Views/RigaArticoloView.swift`. Expiry state is never conveyed by color alone (icon + accessibility label).
- Previews use `.modelContainer(.anteprima)` (in-memory sample data, `Views/Anteprime.swift`, DEBUG only).
- Platform differences are handled inline with `#if os(macOS)` / `#if os(iOS)`.
- `Dispensa/Localizable.xcstrings` (source language `it`) is filled automatically when building from the Xcode IDE, not from `xcodebuild`.

## Build settings that affect how code is written

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`: types are main-actor isolated by default; mark code `nonisolated` (or use `@concurrent`) explicitly when it must run off the main actor.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`: each file must import the modules whose members it uses (transitive imports don't expose members).
- Swift language mode 5.0.
- App Sandbox and Hardened Runtime are enabled (macOS); user-selected file access is read-only.
- String Catalogs are preferred for localization (`LOCALIZATION_PREFERS_STRING_CATALOGS`, `STRING_CATALOG_GENERATE_SYMBOLS`); development language is Italian (`"development": "it"`).

## Tests

- `DispensaTests` uses **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest. Each suite is a `@MainActor struct` (the test target is not MainActor-isolated by default) that gets a fresh in-memory container from `creaContainerDiTest()` (`DispensaTests/SupportoTest.swift`).
- `DispensaUITests` uses XCTest/XCUIApplication and launches the app with `--in-memoria` (handled in `DispensaApp.swift`) so it never touches real data. Reuse the helpers in `DispensaUITests.swift` (`avviaConDispensa` — creates "Casa", which opens on Strutture —, `apri(scheda:)`, `creaEApriStruttura`, `tocca(rigaCheIniziaCon:)`, `scrivi(_:nelPrimoCampoDi:)`, `scrivi(_:nelCampoConEsempio:in:)`, `aumenta`, `allegaScreenshot`). These are iPhone tests.
- `NavigazioneMacUITests.swift` (`#if os(macOS)`, runs only with `-destination 'platform=macOS'`) checks that Mac rows stay clickable after tab switches, Indietro, storico selection and edits. On the Mac use `click()`, sidebar items via `app.outlines.staticTexts["Articoli"]`, the back button via `app.toolbars.buttons["Indietro"]`.
- Accessibility quirks the UI tests rely on: `LabeledContent` rows are a single `"Label, Value"` static text; text fields with a `prompt` are found by placeholder, not label (use `app.textFields.firstMatch`); list rows are buttons whose label joins all texts (match with `BEGINSWITH`); the iPhone back button has identifier `BackButton`; tabs are `app.tabBars.buttons["Storico"]`.
