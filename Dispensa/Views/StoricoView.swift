//
//  StoricoView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Articoli consumati o buttati di una dispensa, dal più recente.
struct StoricoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa

    @State private var ricerca = ""
    @State private var selezione = Set<Articolo.ID>()
    @State private var daRimettere: Articolo?
    @State private var confermaSvuota = false
    @State private var errore: String?
#if os(iOS)
    @State private var modalitaModifica = EditMode.inactive
#endif

    private var articoli: [Articolo] {
        let testo = ricerca.trimmingCharacters(in: .whitespacesAndNewlines)
        let storico = dispensa.articoliNelloStorico
        guard !testo.isEmpty else { return storico }
        return storico.filter { $0.nomeVisualizzato.localizedStandardContains(testo) }
    }

    private var selezionati: [Articolo] {
        articoli.filter { selezione.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List(selection: $selezione) {
                ForEach(articoli) { articolo in
                    RigaStoricoView(articolo: articolo)
                        .swipeActions(edge: .leading) {
                            Button("Rimetti in dispensa", systemImage: "arrow.uturn.backward") { rimetti(articolo) }
                                .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Elimina", systemImage: "trash", role: .destructive) {
                                modelContext.eliminaDalloStorico([articolo])
                            }
                        }
                        .contextMenu {
                            Button("Rimetti in dispensa", systemImage: "arrow.uturn.backward") { rimetti(articolo) }
                            Button("Elimina dallo storico", systemImage: "trash", role: .destructive) {
                                modelContext.eliminaDalloStorico([articolo])
                            }
                        }
                }
            }
            .navigationTitle("Storico")
            .searchable(text: $ricerca, prompt: Text("Cerca per nome"))
#if os(iOS)
            .environment(\.editMode, $modalitaModifica)
#endif
            .overlay { statoVuoto }
            .toolbar { barra }
            .sheet(item: $daRimettere) { articolo in
                RimettiInDispensaView(articolo: articolo)
            }
            .confirmationDialog("Svuotare lo storico?", isPresented: $confermaSvuota, titleVisibility: .visible) {
                Button("Svuota storico", role: .destructive) {
                    modelContext.svuotaStorico(di: dispensa)
                    selezione.removeAll()
                }
            } message: {
                Text("Verranno eliminati tutti gli articoli consumati e buttati di «\(dispensa.nome)». L'operazione non si può annullare.")
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } }),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore)
            }
        }
#if os(macOS)
        .frame(minWidth: 440, minHeight: 480)
#endif
    }

    @ViewBuilder
    private var statoVuoto: some View {
        if dispensa.articoliNelloStorico.isEmpty {
            if dispensa.storicoAbilitato {
                ContentUnavailableView(
                    "Storico vuoto",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Qui compariranno gli articoli consumati o buttati.")
                )
            } else {
                ContentUnavailableView(
                    "Storico disattivato",
                    systemImage: "clock.badge.xmark",
                    description: Text("Puoi attivarlo modificando la dispensa.")
                )
            }
        } else if articoli.isEmpty {
            ContentUnavailableView.search(text: ricerca)
        }
    }

    @ToolbarContentBuilder
    private var barra: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Fine") { dismiss() }
        }
#if os(iOS)
        if !dispensa.articoliNelloStorico.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
#endif
        ToolbarItem(placement: .primaryAction) {
            if selezionati.isEmpty {
                Button("Svuota storico", systemImage: "trash", role: .destructive) { confermaSvuota = true }
                    .disabled(dispensa.articoliNelloStorico.isEmpty)
            } else {
                Button("Elimina selezionati (\(selezionati.count))", systemImage: "trash", role: .destructive) {
                    modelContext.eliminaDalloStorico(selezionati)
                    selezione.removeAll()
                }
            }
        }
    }

    /// Se c'è da scegliere (più parti o struttura eliminata) apre il modulo, altrimenti rimette subito.
    private func rimetti(_ articolo: Articolo) {
        guard articolo.partiTotali == 1, articolo.struttura != nil else {
            daRimettere = articolo
            return
        }
        do {
            try modelContext.rimettiInDispensa(articolo)
        } catch {
            errore = error.localizedDescription
        }
    }
}

/// Riga di un articolo nello storico: come è uscito, quando e da dove.
private struct RigaStoricoView: View {
    let articolo: Articolo

    private var esito: String {
        switch (articolo.stato, articolo.motivoScarto) {
        case (.buttato, let motivo?):
            String(localized: "Buttato (\(String(localized: motivo.nomeLocalizzato)))")
        case (.buttato, nil):
            String(localized: "Buttato")
        default:
            String(localized: "Consumato")
        }
    }

    private var dettagli: String {
        var parti = [esito]
        if let dataUscita = articolo.dataUscita {
            parti.append(dataUscita.formatted(date: .abbreviated, time: .omitted))
        }
        if let struttura = articolo.struttura {
            parti.append(struttura.nome)
        }
        return parti.joined(separator: " · ")
    }

    var body: some View {
        HStack {
            Image(systemName: articolo.stato == .buttato ? "trash.slash" : "checkmark.circle")
                .foregroundStyle(articolo.stato == .buttato ? .orange : .green)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(articolo.nomeVisualizzato)
                Text(dettagli)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Spreco parziale: alcune parti consumate, altre buttate.
                if articolo.partiButtate > 0, articolo.partiButtate < articolo.partiTotali {
                    Text("Parti buttate: \(articolo.partiButtate) di \(articolo.partiTotali)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

/// Modulo per rimettere in dispensa un articolo dello storico, scegliendo parti e struttura.
private struct RimettiInDispensaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let articolo: Articolo

    @State private var parti = 1
    @State private var struttura: Struttura?
    @State private var errore: String?

    init(articolo: Articolo) {
        self.articolo = articolo
        _struttura = State(initialValue: articolo.struttura)
    }

    private var strutture: [Struttura] {
        (articolo.dispensa?.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(articolo.nomeVisualizzato)
                }
                if articolo.partiTotali > 1 {
                    Section {
                        Stepper(value: $parti, in: 1...articolo.partiTotali) {
                            LabeledContent("Parti da rimettere") {
                                Text("\(parti) di \(articolo.partiTotali)")
                            }
                        }
                    }
                }
                Section {
                    Picker("Struttura", selection: $struttura) {
                        if struttura == nil {
                            Text("Scegli").tag(nil as Struttura?)
                        }
                        ForEach(strutture) { struttura in
                            Label(struttura.nome, systemImage: struttura.tipo.simbolo)
                                .tag(struttura as Struttura?)
                        }
                    }
                } footer: {
                    if articolo.struttura == nil {
                        Text("La struttura originale non esiste più: scegline un'altra.")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Rimetti in dispensa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rimetti", action: rimetti)
                        .disabled(struttura == nil)
                }
            }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } }),
                presenting: errore
            ) { _ in
                Button("OK") {}
            } message: { errore in
                Text(errore)
            }
        }
#if os(macOS)
        .frame(minWidth: 380, minHeight: 300)
#endif
    }

    private func rimetti() {
        do {
            try modelContext.rimettiInDispensa(articolo, parti: parti, in: struttura)
            dismiss()
        } catch {
            errore = error.localizedDescription
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    StoricoView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
