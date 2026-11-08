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

# All tests (unit + UI)
xcodebuild -scheme Dispensa -destination 'platform=iOS Simulator,name=iPhone 17' test

# Unit tests only / a single test
xcodebuild ... test -only-testing:DispensaTests
xcodebuild ... test -only-testing:DispensaTests/DispensaTests/example
```

There is no linter or formatter configured.

## Project file format

`Dispensa.xcodeproj/project.xcproj` is Xcode's JSON-style project format, not a classic `project.pbxproj`. Targets use **folder-based membership** (`"kind": "folder"` entries mapping `Dispensa/`, `DispensaTests/`, `DispensaUITests/` to their targets), so new source files dropped into those folders (including subfolders) are picked up automatically — no project-file edits are needed to add files.

## Architecture

- `DispensaApp.swift` builds the single persistent `ModelContainer` from `SchemaDispensa.schema`. Any new `@Model` type must be added to `SchemaDispensa.modelli` (`Dispensa/Models/SchemaDispensa.swift`), which is also used by previews and tests.
- Everything hangs off `Dispensa` (the future CloudKit share root): its relationships cascade. `Struttura → Articolo` and `Ubicazione → Struttura` are *nullify*, so the history (storico) survives deleting a struttura. Relationships are set after `context.insert(...)`, not in initializers.
- Model tests use an in-memory `ModelContainer` in a `@MainActor` test struct (the test target is not MainActor-isolated by default); see `DispensaTests/ModelliTests.swift`.
- Views get persistence via `@Environment(\.modelContext)` and `@Query`.
- UI entry point is `Views/RootView.swift`: a 3-column `NavigationSplitView` (Dispense → Strutture → dettaglio) that collapses to a stack on iPhone. Selection is passed down as `@Binding`.
- Forms (`*FormView`) edit local `@State` copies and write to the model only on "Salva"; `nil` model means "create new".
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

- `DispensaTests` uses **Swift Testing** (`import Testing`, `@Test`, `#expect`), not XCTest.
- `DispensaUITests` uses XCTest/XCUIApplication and launches the app with `--in-memoria` (handled in `DispensaApp.swift`) so it never touches real data. Note: `LabeledContent` rows are exposed to accessibility as a single `"Label, Value"` static text; text fields with a `prompt` are found by placeholder, not label.
- Logic that mutates several models (e.g. `ModelContext.eliminaStruttura` in `Services/`) lives in `Services/` as `ModelContext` extensions and is unit-tested.
