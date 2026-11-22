//
//  FiltriArticoliView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

extension View {
    /// Aggiunge il pulsante "Filtri" nella barra e il foglio per sceglierli (schede Articoli e Storico).
    func filtriArticoli(_ filtro: Binding<FiltroArticoli>, dispensa: Dispensa, perStorico: Bool) -> some View {
        modifier(ModificatoreFiltri(filtro: filtro, dispensa: dispensa, perStorico: perStorico))
    }
}

private struct ModificatoreFiltri: ViewModifier {
    @Binding var filtro: FiltroArticoli
    let dispensa: Dispensa
    let perStorico: Bool

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
            .sheet(isPresented: $aperto) {
                FiltriArticoliView(dispensa: dispensa, perStorico: perStorico, filtro: $filtro)
            }
    }
}

/// Prima riga di un elenco filtrato: quanti filtri sono attivi e il pulsante per toglierli.
struct RigaFiltriAttivi: View {
    @Binding var filtro: FiltroArticoli

    var body: some View {
        HStack {
            Label("Filtri attivi: \(filtro.numeroAttivi)", systemImage: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Azzera") { filtro = FiltroArticoli() }
                .buttonStyle(.borderless)
        }
        .font(.subheadline)
    }
}

/// Messaggio per un elenco vuoto a causa dei filtri.
struct NessunRisultatoConFiltri: View {
    @Binding var filtro: FiltroArticoli

    var body: some View {
        ContentUnavailableView {
            Label("Nessun articolo con questi filtri", systemImage: "line.3.horizontal.decrease.circle")
        } actions: {
            Button("Azzera filtri") { filtro = FiltroArticoli() }
        }
    }
}

/// Foglio con tutti i filtri sugli articoli. Le modifiche valgono subito; "Fine" chiude.
struct FiltriArticoliView: View {
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    /// Nello storico ci sono anche esito (consumato o buttato) e data di uscita.
    let perStorico: Bool
    @Binding var filtro: FiltroArticoli

    private var strutture: [Struttura] {
        (dispensa.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    /// Solo i tipi delle strutture che esistono.
    private var tipi: [TipoStruttura] {
        let presenti = Set(strutture.map(\.tipo))
        return TipoStruttura.allCases.filter(presenti.contains)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !strutture.isEmpty {
                    Section("Strutture") {
                        ForEach(strutture) { struttura in
                            rigaConSpunta(filtro.strutture.contains(struttura.id)) {
                                filtro.strutture.inverti(struttura.id)
                            } contenuto: {
                                Label(struttura.nome, systemImage: struttura.tipo.simbolo)
                            }
                        }
                    }
                }
                if tipi.count > 1 {
                    Section("Tipo di struttura") {
                        ForEach(tipi) { tipo in
                            rigaConSpunta(filtro.tipiStruttura.contains(tipo)) {
                                filtro.tipiStruttura.inverti(tipo)
                            } contenuto: {
                                Label { Text(tipo.nomeLocalizzato) } icon: { Image(systemName: tipo.simbolo) }
                            }
                        }
                    }
                }
                sezioneCategorie
                sezioneEtichette

                Section("Scadenza") {
                    ForEach(StatoScadenza.allCases) { stato in
                        rigaConSpunta(filtro.scadenze.contains(stato)) {
                            filtro.scadenze.inverti(stato)
                        } contenuto: {
                            Label { Text(stato.nomeLocalizzato) } icon: { Image(systemName: stato.simbolo) }
                        }
                    }
                }

                if perStorico {
                    Section("Esito") {
                        ForEach([StatoArticolo.consumato, .buttato]) { esito in
                            rigaConSpunta(filtro.esiti.contains(esito)) {
                                filtro.esiti.inverti(esito)
                            } contenuto: {
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

                Section {
                    Button("Azzera filtri", systemImage: "xmark.circle", role: .destructive) {
                        filtro = FiltroArticoli()
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

    @ViewBuilder
    private var sezioneCategorie: some View {
        let categorie = dispensa.categorieInOrdine
        if !categorie.isEmpty {
            Section {
                ForEach(categorie) { categoria in
                    rigaConSpunta(filtro.categorie.contains(categoria.id)) {
                        filtro.categorie.inverti(categoria.id)
                    } contenuto: {
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

    @ViewBuilder
    private var sezioneEtichette: some View {
        let etichette = dispensa.etichetteOrdinate
        if !etichette.isEmpty {
            Section("Etichette") {
                ForEach(etichette) { etichetta in
                    rigaConSpunta(filtro.etichette.contains(etichetta.id)) {
                        filtro.etichette.inverti(etichetta.id)
                    } contenuto: {
                        GettoneEtichettaView(etichetta)
                    }
                }
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

    /// Riga che si sceglie o si toglie con un tocco, con la spunta quando è scelta.
    private func rigaConSpunta<Contenuto: View>(
        _ scelta: Bool,
        azione: @escaping () -> Void,
        @ViewBuilder contenuto: () -> Contenuto
    ) -> some View {
        Button(action: azione) {
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

private extension Set {
    /// Aggiunge l'elemento se manca, lo toglie se c'è.
    mutating func inverti(_ elemento: Element) {
        if contains(elemento) {
            remove(elemento)
        } else {
            insert(elemento)
        }
    }
}
