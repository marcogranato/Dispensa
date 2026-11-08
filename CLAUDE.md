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

# Inspect a UI test run (screenshots, view hierarchy on failure)
xcodebuild ... -resultBundlePath <scratch>/ui.xcresult test -only-testing:DispensaUITests
xcrun xcresulttool export attachments --path <scratch>/ui.xcresult --output-path <scratch>/att   # manifest.json maps files to tests
```

There is no linter or formatter configured.

## Project file format

`Dispensa.xcodeproj/project.xcproj` is Xcode's JSON-style project format, not a classic `project.pbxproj`. Targets use **folder-based membership** (`"kind": "folder"` entries mapping `Dispensa/`, `DispensaTests/`, `DispensaUITests/` to their targets), so new source files dropped into those folders (including subfolders) are picked up automatically — no project-file edits are needed to add files.

## Architecture

- `DispensaApp.swift` builds the single persistent `ModelContainer` from `SchemaDispensa.schema`. Any new `@Model` type must be added to `SchemaDispensa.modelli` (`Dispensa/Models/SchemaDispensa.swift`), which is also used by previews and tests.
- Everything hangs off `Dispensa` (the future CloudKit share root): its relationships cascade. `Struttura → Articolo` and `Ubicazione → Struttura` are *nullify*, so the history (storico) survives deleting a struttura. Relationships are set after `context.insert(...)`, not in initializers.
- Article lifecycle: an `Articolo` is *attivo* while in a struttura; when its `partiRimaste` reach 0 (via `preleva`/`butta`) it becomes `consumato`/`buttato` with `dataUscita` (the storico), or is deleted if `Dispensa.storicoAbilitato` is false. `partiButtate` counts waste exactly; `StatoScadenza` (scaduto / in scadenza ≤ 3 days) is computed, never stored.
- Business rules live in `Services/` as `ModelContext` extensions and are unit-tested: `GestioneArticoli.swift` (preleva, butta, sposta with confezione split, rimettiInDispensa, storico cleanup, eliminaProdotto), `AggiuntaArticoli.swift` (`DatiArticolo`, `trovaOCreaProdotto`, `aggiungiArticoli`), `GestioneStrutture.swift`. They validate input and throw `ErroreGestioneArticoli` (a `LocalizedError` with Italian messages) instead of corrupting data; views show `error.localizedDescription` in an alert. Put new multi-model logic here, not in views.
- Views get persistence via `@Environment(\.modelContext)`; lists mostly read relationships of the selected `Dispensa`/`Struttura` (e.g. `dispensa.articoliNelloStorico`, `struttura.articoliAttivi`) rather than `@Query`.
- UI entry point is `Views/RootView.swift`: a 3-column `NavigationSplitView` (Dispense → Strutture → dettaglio) that collapses to a stack on iPhone. Selection is passed down as `@Binding`. Per-dispensa tools (Prodotti, Ubicazioni, Storico) open as sheets from the "Altro" menu in `ElencoStruttureView`.
- The detail column wraps `DettaglioStrutturaView` in its own `NavigationStack` (reset with `.id`) so articles can be pushed with `NavigationLink(value:)`.
- Article actions (preleva / butta / sposta / modifica / elimina) are shared via `MenuAzioniArticolo` and the `.azioniArticolo(_:daEliminare:)` modifier in `Views/AzioniArticolo.swift`; views only hold the two `@State` bindings.
- Views showing a single article must guard against it leaving the pantry or being deleted (`isDeleted`, `modelContext == nil`, `stato != .attivo`) — see `DettaglioArticoloView`.
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
- `DispensaUITests` uses XCTest/XCUIApplication and launches the app with `--in-memoria` (handled in `DispensaApp.swift`) so it never touches real data. Reuse the helpers in `DispensaUITests.swift` (`avviaConDispensa`, `creaEApriStruttura`, `tocca(rigaCheIniziaCon:)`, `scrivi`, `aumenta`, `allegaScreenshot`).
- Accessibility quirks the UI tests rely on: `LabeledContent` rows are a single `"Label, Value"` static text; text fields with a `prompt` are found by placeholder, not label (use `app.textFields.firstMatch`); list rows are buttons whose label joins all texts (match with `BEGINSWITH`); the iPhone back button has identifier `BackButton`.
