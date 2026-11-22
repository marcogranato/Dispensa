//
//  FiltriArticoliView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Dove si usano i filtri sugli articoli: decide quali sezioni compaiono nel foglio.
enum ContestoFiltri {
    /// Scheda Articoli: tutti i filtri sugli articoli presenti.
    case articoli
    /// Storico: in più esito (consumato o buttato) e data di uscita.
    case storico
    /// Scheda di una struttura: senza strutture e tipo di struttura.
    case struttura
}

extension View {
    /// Aggiunge il pulsante "Filtri" nella barra e il foglio per scegliere i filtri sugli articoli.
    /// `dispensa` è facoltativa solo per comodità della scheda della struttura (`struttura.dispensa`).
    func filtriArticoli(_ filtro: Binding<FiltroArticoli>, dispensa: Dispensa?, contesto: ContestoFiltri) -> some View {
        modifier(PulsanteFiltri(filtro: filtro) {
            if let dispensa {
                FiltriArticoliView(dispensa: dispensa, contesto: contesto, filtro: filtro)
            }
        })
    }
}

/// Pulsante "Filtri" per la barra (icona piena quando ci sono filtri attivi) e il foglio che apre.
struct PulsanteFiltri<Filtro: FiltroElenco, Foglio: View>: ViewModifier {
    @Binding var filtro: Filtro
    @ViewBuilder let foglio: () -> Foglio

    @State private var aperto = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem {
                    Button {
                        aperto = true
                    } label: {
                        Label(
                            "Filtri",
                            systemImage: filtro.vuoto
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill"
                        )
                    }
                    .accessibilityValue(filtro.vuoto ? Text("") : Text("Attivi: \(filtro.numeroAttivi)"))
                }
            }
            .sheet(isPresented: $aperto, content: foglio)
    }
}

/// Prima riga di un elenco filtrato: quanti filtri sono attivi e il pulsante per toglierli.
struct RigaFiltriAttivi<Filtro: FiltroElenco>: View {
    @Binding var filtro: Filtro

    var body: some View {
        HStack {
            Label("Filtri attivi: \(filtro.numeroAttivi)", systemImage: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Azzera") { filtro = Filtro() }
                .buttonStyle(.borderless)
        }
        .font(.subheadline)
    }
}

/// Messaggio per un elenco vuoto a causa dei filtri.
struct NessunRisultatoConFiltri<Filtro: FiltroElenco>: View {
    var titolo: LocalizedStringKey = "Nessun articolo con questi filtri"
    @Binding var filtro: Filtro

    var body: some View {
        ContentUnavailableView {
            Label(titolo, systemImage: "line.3.horizontal.decrease.circle")
        } actions: {
            Button("Azzera filtri") { filtro = Filtro() }
        }
    }
}

/// Foglio con tutti i filtri sugli articoli. Le modifiche valgono subito; "Fine" chiude.
struct FiltriArticoliView: View {
    let dispensa: Dispensa
    let contesto: ContestoFiltri
    @Binding var filtro: FiltroArticoli

    private var strutture: [Struttura] {
        (dispensa.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    /// Solo i tipi delle strutture che esistono.
    private var tipi: [TipoStruttura] {
        let presenti = Set(strutture.map(\.tipo))
        return TipoStruttura.allCases.filter(presenti.contains)
    }

    private var perStorico: Bool { contesto == .storico }

    var body: some View {
        FoglioFiltri(filtro: $filtro) {
            if contesto != .struttura {
                if !strutture.isEmpty {
                    Section("Strutture") {
                        ForEach(strutture) { struttura in
                            RigaConSpunta(selezione: $filtro.strutture, valore: struttura.id) {
                                Label(struttura.nome, systemImage: struttura.tipo.simbolo)
                            }
                        }
                    }
                }
                if tipi.count > 1 {
                    Section("Tipo di struttura") {
                        ForEach(tipi) { tipo in
                            RigaConSpunta(selezione: $filtro.tipiStruttura, valore: tipo) {
                                Label { Text(tipo.nomeLocalizzato) } icon: { Image(systemName: tipo.simbolo) }
                            }
                        }
                    }
                }
            }
            SezioneFiltroCategorie(dispensa: dispensa, selezione: $filtro.categorie)
            SezioneFiltroEtichette(dispensa: dispensa, selezione: $filtro.etichette)

            Section("Scadenza") {
                ForEach(StatoScadenza.allCases) { stato in
                    RigaConSpunta(selezione: $filtro.scadenze, valore: stato) {
                        Label { Text(stato.nomeLocalizzato) } icon: { Image(systemName: stato.simbolo) }
                    }
                }
            }

            if perStorico {
                Section("Esito") {
                    ForEach([StatoArticolo.consumato, .buttato]) { esito in
                        RigaConSpunta(selezione: $filtro.esiti, valore: esito) {
                            Text(esito.nomeLocalizzato)
                        }
                    }
                }
            }

            sezioneDate("Data di scadenza", intervallo: $filtro.scadenza)
            sezioneDate("Data di inserimento", intervallo: $filtro.inserimento)
            sezioneDate("Data di produzione", intervallo: $filtro.produzione)
            if perStorico {
                sezioneDate("Data di uscita", intervallo: $filtro.uscita)
            }
        }
    }

    private func sezioneDate(_ titolo: LocalizedStringKey, intervallo: Binding<IntervalloDate>) -> some View {
        Section {
            RigaDataFacoltativa("Dal", data: intervallo.dal)
            RigaDataFacoltativa("Al", data: intervallo.al)
        } header: {
            Text(titolo)
        }
    }
}

// MARK: - Componenti comuni dei fogli dei filtri

/// Struttura comune dei fogli dei filtri: il modulo con le sezioni, "Azzera filtri" in fondo e "Fine" in alto.
struct FoglioFiltri<Filtro: FiltroElenco, Sezioni: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filtro: Filtro
    @ViewBuilder let sezioni: () -> Sezioni

    var body: some View {
        NavigationStack {
            Form {
                sezioni()
                Section {
                    Button("Azzera filtri", systemImage: "xmark.circle", role: .destructive) {
                        filtro = Filtro()
                    }
                    .disabled(filtro.vuoto)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Filtri")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
#endif
    }
}

/// L'albero delle categorie con le spunte (non compare se non ci sono categorie).
struct SezioneFiltroCategorie: View {
    let dispensa: Dispensa
    @Binding var selezione: Set<UUID>

    var body: some View {
        let categorie = dispensa.categorieInOrdine
        if !categorie.isEmpty {
            Section {
                ForEach(categorie) { categoria in
                    RigaConSpunta(selezione: $selezione, valore: categoria.id) {
                        RigaCategoriaView(categoria: categoria, rientrata: true)
                    }
                }
            } header: {
                Text("Categorie")
            } footer: {
                Text("Una categoria comprende le sue sottocategorie.")
            }
        }
    }
}

/// Le etichette con le spunte (non compare se non ci sono etichette).
struct SezioneFiltroEtichette: View {
    let dispensa: Dispensa
    @Binding var selezione: Set<UUID>

    var body: some View {
        let etichette = dispensa.etichetteOrdinate
        if !etichette.isEmpty {
            Section("Etichette") {
                ForEach(etichette) { etichetta in
                    RigaConSpunta(selezione: $selezione, valore: etichetta.id) {
                        GettoneEtichettaView(etichetta)
                    }
                }
            }
        }
    }
}

/// Riga che aggiunge o toglie `valore` dalla selezione con un tocco, con la spunta quando è scelta.
struct RigaConSpunta<Valore: Hashable, Contenuto: View>: View {
    @Binding var selezione: Set<Valore>
    let valore: Valore
    @ViewBuilder let contenuto: () -> Contenuto

    private var scelta: Bool { selezione.contains(valore) }

    var body: some View {
        Button {
            if scelta {
                selezione.remove(valore)
            } else {
                selezione.insert(valore)
            }
        } label: {
            HStack {
                contenuto()
                Spacer()
                if scelta {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(scelta ? .isSelected : [])
    }
}
