//
//  ArticoloFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per aggiungere articoli (`articolo == nil`) o modificarne uno esistente.
/// Il prodotto si sceglie scrivendo il nome: se non esiste, viene creato al salvataggio.
struct ArticoloFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let articolo: Articolo?

    @State private var nomeProdotto: String
    @State private var dati: DatiArticolo
    @State private var struttura: Struttura?
    @State private var partiRimaste: Int
    @State private var confezioni = 1
    @FocusState private var nomeInModifica: Bool

    init(dispensa: Dispensa, struttura: Struttura?, articolo: Articolo? = nil) {
        self.dispensa = dispensa
        self.articolo = articolo
        _nomeProdotto = State(initialValue: articolo?.prodotto?.nome ?? "")
        _dati = State(initialValue: articolo.map(DatiArticolo.init(articolo:)) ?? DatiArticolo())
        _struttura = State(initialValue: articolo?.struttura ?? struttura)
        _partiRimaste = State(initialValue: articolo?.partiRimaste ?? 1)
    }

    private var nomePulito: String {
        nomeProdotto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var prodottoEsistente: Prodotto? {
        dispensa.prodotto(nominato: nomePulito)
    }

    /// Prodotti che contengono il testo scritto (al massimo 5), escluso quello già scelto.
    private var suggerimenti: [Prodotto] {
        guard nomeInModifica, !nomePulito.isEmpty else { return [] }
        return (dispensa.prodotti ?? [])
            .filter { $0.nome.localizedStandardContains(nomePulito) && $0 !== prodottoEsistente }
            .sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
            .prefix(5)
            .map { $0 }
    }

    private var strutture: [Struttura] {
        (dispensa.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Form {
                sezioneProdotto
                sezioneStruttura
                sezioneConfezione
                sezioneDate
            }
            .formStyle(.grouped)
            .navigationTitle(articolo == nil ? Text("Nuovo articolo") : Text("Modifica articolo"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nomePulito.isEmpty || struttura == nil)
                }
            }
            .onChange(of: dati.partiTotali) {
                partiRimaste = min(partiRimaste, dati.partiTotali)
            }
        }
#if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
#endif
    }

    private var sezioneProdotto: some View {
        Section {
            TextField("Prodotto", text: $nomeProdotto, prompt: Text("Es. Latte, Biscotti"))
                .focused($nomeInModifica)
                .onSubmit { nomeInModifica = false }
            ForEach(suggerimenti) { prodotto in
                Button {
                    scegli(prodotto)
                } label: {
                    Label(prodotto.nome, systemImage: "arrow.up.left")
                }
            }
        } header: {
            Text("Prodotto")
        } footer: {
            if !nomePulito.isEmpty, prodottoEsistente == nil {
                Text("Verrà creato il nuovo prodotto «\(nomePulito)».")
            }
        }
    }

    private var sezioneStruttura: some View {
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
        }
    }

    private var sezioneConfezione: some View {
        Section("Confezione") {
            Stepper(value: $dati.partiTotali, in: 1...100) {
                LabeledContent("Parti per confezione") {
                    Text(dati.partiTotali, format: .number)
                }
            }
            if articolo != nil, dati.partiTotali > 1 {
                Stepper(value: $partiRimaste, in: 1...dati.partiTotali) {
                    LabeledContent("Parti rimaste") {
                        Text(partiRimaste, format: .number)
                    }
                }
            }
            LabeledContent("Quantità per parte") {
                TextField("Quantità per parte", value: $dati.quantitaPerParte, format: .number, prompt: Text("Facoltativa"))
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            Picker("Unità", selection: $dati.unita) {
                Text("Nessuna").tag(nil as Unita?)
                ForEach(Unita.allCases) { unita in
                    Text(unita.nomeLocalizzato).tag(unita as Unita?)
                }
            }
            if articolo == nil {
                Stepper(value: $confezioni, in: 1...50) {
                    LabeledContent("Confezioni da aggiungere") {
                        Text(confezioni, format: .number)
                    }
                }
            }
        }
    }

    private var sezioneDate: some View {
        Section("Date") {
            DatePicker("Inserimento", selection: $dati.dataInserimento, displayedComponents: .date)
            dataFacoltativa("Produzione", data: $dati.dataProduzione)
            dataFacoltativa("Scadenza", data: $dati.dataScadenza)
        }
    }

    /// Data facoltativa su una sola riga: "Aggiungi" se manca, altrimenti il selettore e un pulsante per toglierla.
    @ViewBuilder
    private func dataFacoltativa(_ titolo: LocalizedStringKey, data: Binding<Date?>) -> some View {
        if let valore = data.wrappedValue {
            HStack {
                DatePicker(
                    titolo,
                    selection: Binding(get: { valore }, set: { data.wrappedValue = $0 }),
                    displayedComponents: .date
                )
                Button("Rimuovi data", systemImage: "xmark.circle.fill") {
                    data.wrappedValue = nil
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .buttonStyle(.borderless)
            }
        } else {
            LabeledContent(titolo) {
                Button("Aggiungi") {
                    data.wrappedValue = Calendar.current.startOfDay(for: .now)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// Sceglie un prodotto suggerito; per un nuovo articolo propone i valori della sua confezione.
    private func scegli(_ prodotto: Prodotto) {
        nomeProdotto = prodotto.nome
        nomeInModifica = false
        if articolo == nil {
            var proposti = DatiArticolo(prodotto: prodotto)
            proposti.dataInserimento = dati.dataInserimento
            proposti.dataProduzione = dati.dataProduzione
            proposti.dataScadenza = dati.dataScadenza
            dati = proposti
        }
    }

    private func salva() {
        guard let struttura else { return }
        if let quantita = dati.quantitaPerParte, quantita <= 0 {
            dati.quantitaPerParte = nil
        }
        let prodotto = modelContext.trovaOCreaProdotto(nominato: nomePulito, in: dispensa, dati: dati)
        if let articolo {
            dati.applica(a: articolo)
            articolo.partiRimaste = min(partiRimaste, dati.partiTotali)
            articolo.prodotto = prodotto
            articolo.struttura = struttura
        } else {
            modelContext.aggiungiArticoli(dati, prodotto: prodotto, struttura: struttura, confezioni: confezioni)
        }
        dismiss()
    }
}

#Preview {
    let struttura = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Struttura>(sortBy: [SortDescriptor(\.nome)])).first!
    ArticoloFormView(dispensa: struttura.dispensa!, struttura: struttura)
        .modelContainer(.anteprima)
}
