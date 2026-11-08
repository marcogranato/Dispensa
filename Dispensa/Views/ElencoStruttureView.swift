//
//  ElencoStruttureView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Strutture di una dispensa, raggruppate per ubicazione.
struct ElencoStruttureView: View {
    @Environment(\.modelContext) private var modelContext

    let dispensa: Dispensa
    @Binding var selezione: Struttura?

    @State private var mostraNuovaStruttura = false
    @State private var mostraUbicazioni = false
    @State private var strutturaInModifica: Struttura?
    @State private var strutturaDaEliminare: Struttura?

    private struct Gruppo: Identifiable {
        let ubicazione: Ubicazione?
        let strutture: [Struttura]
        var id: PersistentIdentifier? { ubicazione?.persistentModelID }
    }

    /// Un gruppo per ogni ubicazione che contiene strutture, in ordine alfabetico; in fondo quelle senza ubicazione.
    private var gruppi: [Gruppo] {
        let strutture = (dispensa.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
        let perUbicazione = Dictionary(grouping: strutture) { $0.ubicazione?.persistentModelID }
        let ubicazioni = (dispensa.ubicazioni ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
        var risultato = ubicazioni.compactMap { ubicazione in
            perUbicazione[ubicazione.persistentModelID].map { Gruppo(ubicazione: ubicazione, strutture: $0) }
        }
        if let senzaUbicazione = perUbicazione[nil] {
            risultato.append(Gruppo(ubicazione: nil, strutture: senzaUbicazione))
        }
        return risultato
    }

    var body: some View {
        List(selection: $selezione) {
            ForEach(gruppi) { gruppo in
                Section {
                    ForEach(gruppo.strutture) { struttura in
                        riga(struttura)
                    }
                } header: {
                    if let ubicazione = gruppo.ubicazione {
                        Text(ubicazione.nome)
                    } else {
                        Text("Senza ubicazione")
                    }
                }
            }
        }
        .navigationTitle(dispensa.nome)
        .overlay {
            if dispensa.strutture?.isEmpty ?? true {
                ContentUnavailableView {
                    Label("Nessuna struttura", systemImage: "square.stack.3d.up")
                } description: {
                    Text("Aggiungi frigorifero, congelatore, scaffali e gli altri spazi dove conservi il cibo.")
                } actions: {
                    Button("Aggiungi una struttura") { mostraNuovaStruttura = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Ubicazioni", systemImage: "mappin.and.ellipse") { mostraUbicazioni = true }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Nuova struttura", systemImage: "plus") { mostraNuovaStruttura = true }
            }
        }
        .sheet(isPresented: $mostraNuovaStruttura) {
            StrutturaFormView(dispensa: dispensa)
        }
        .sheet(item: $strutturaInModifica) { struttura in
            StrutturaFormView(dispensa: dispensa, struttura: struttura)
        }
        .sheet(isPresented: $mostraUbicazioni) {
            UbicazioniView(dispensa: dispensa)
        }
        .confirmationDialog(
            "Eliminare la struttura?",
            isPresented: Binding(
                get: { strutturaDaEliminare != nil },
                set: { if !$0 { strutturaDaEliminare = nil } }
            ),
            titleVisibility: .visible,
            presenting: strutturaDaEliminare
        ) { struttura in
            Button("Elimina", role: .destructive) { elimina(struttura) }
        } message: { struttura in
            Text("Articoli presenti in «\(struttura.nome)»: \(struttura.articoliAttivi.count). Verranno eliminati; lo storico resta.")
        }
    }

    private func riga(_ struttura: Struttura) -> some View {
        NavigationLink(value: struttura) {
            HStack {
                Label {
                    VStack(alignment: .leading) {
                        Text(struttura.nome)
                        if struttura.nomeTipo != struttura.nome {
                            Text(struttura.nomeTipo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: struttura.tipo.simbolo)
                }
                Spacer()
                Text(struttura.articoliAttivi.count, format: .number)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityLabel(Text("Articoli presenti: \(struttura.articoliAttivi.count)"))
            }
        }
        .contextMenu {
            pulsanteModifica(struttura)
            pulsanteElimina(struttura)
        }
        .swipeActions {
            pulsanteElimina(struttura)
            pulsanteModifica(struttura)
        }
    }

    private func pulsanteModifica(_ struttura: Struttura) -> some View {
        Button("Modifica", systemImage: "pencil") { strutturaInModifica = struttura }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ struttura: Struttura) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) {
            if struttura.articoliAttivi.isEmpty {
                elimina(struttura)
            } else {
                strutturaDaEliminare = struttura
            }
        }
    }

    private func elimina(_ struttura: Struttura) {
        if selezione == struttura {
            selezione = nil
        }
        modelContext.eliminaStruttura(struttura)
    }
}

#Preview {
    @Previewable @State var selezione: Struttura?
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    NavigationStack {
        ElencoStruttureView(dispensa: dispensa, selezione: $selezione)
    }
    .modelContainer(.anteprima)
}
