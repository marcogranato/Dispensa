//
//  ArticoloFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per aggiungere articoli (`articolo == nil`) o modificarne uno esistente.
/// Il prodotto si sceglie scrivendo nome e marca: se non esiste, viene creato al salvataggio,
/// con la categoria e il tipo di parte indicati qui. Per un articolo nuovo si può partire dal codice a barre:
/// se è di un prodotto lo compila, altrimenti viene collegato al prodotto al salvataggio.
struct ArticoloFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let articolo: Articolo?

    @State private var nomeProdotto: String
    @State private var marca: String
    /// Solo per un prodotto nuovo.
    @State private var categoria: Categoria?
    /// Solo per un prodotto nuovo con più parti.
    @State private var tipoParte: TipoParte?
    @State private var mostraNuovaCategoria = false
    @State private var dati: DatiArticolo
    @State private var struttura: Struttura?
    @State private var partiRimaste: Int
    @State private var confezioni = 1
    /// Codice a barre o QR letto o scritto (solo per un articolo nuovo).
    @State private var codice = ""
    @State private var mostraScanner = false
    @FocusState private var nomeInModifica: Bool

    /// `scansiona`: apre subito la fotocamera per leggere il codice del prodotto (dove lo scanner c'è).
    init(dispensa: Dispensa, struttura: Struttura?, articolo: Articolo? = nil, scansiona: Bool = false) {
        self.dispensa = dispensa
        // Lo scanner prende il posto del modulo nello stesso foglio: così si apre subito, senza un secondo foglio.
        _mostraScanner = State(initialValue: scansiona && articolo == nil && ScannerCodici.disponibile)
        self.articolo = articolo
        _nomeProdotto = State(initialValue: articolo?.prodotto?.nome ?? "")
        _marca = State(initialValue: articolo?.prodotto?.marca ?? "")
        _dati = State(initialValue: articolo.map { DatiArticolo(articolo: $0) } ?? DatiArticolo())
        _struttura = State(initialValue: articolo?.struttura ?? struttura)
        _partiRimaste = State(initialValue: articolo?.partiRimaste ?? 1)
    }

    private var nomePulito: String {
        nomeProdotto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var marcaPulita: String {
        marca.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var codicePulito: String {
        codice.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Il prodotto che ha già il codice scritto, se c'è.
    private var prodottoDelCodice: Prodotto? {
        dispensa.prodotto(conCodice: codicePulito)
    }

    private var prodottoEsistente: Prodotto? {
        dispensa.prodotto(nominato: nomePulito, marca: marcaPulita)
    }

    /// Vero quando al salvataggio verrà creato un nuovo prodotto.
    private var prodottoNuovo: Bool {
        !nomePulito.isEmpty && prodottoEsistente == nil
    }

    /// Prodotti che contengono il testo scritto (al massimo 5), escluso quello già scelto.
    private var suggerimenti: [Prodotto] {
        guard nomeInModifica, !nomePulito.isEmpty else { return [] }
        return (dispensa.prodotti ?? [])
            .filter { $0.nome.localizedStandardContains(nomePulito) && $0 !== prodottoEsistente }
            .sorted { $0.nomeConMarca.localizedStandardCompare($1.nomeConMarca) == .orderedAscending }
            .prefix(5)
            .map { $0 }
    }

    private var strutture: [Struttura] {
        (dispensa.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if mostraScanner {
                    ScannerIncorporato { letto in
                        mostraScanner = false
                        usa(letto)
                    }
                    .navigationTitle("Scansiona codice")
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            // Torna al modulo, per scrivere a mano.
                            Button("Annulla") { mostraScanner = false }
                        }
                    }
                } else {
                    modulo
                }
            }
            .onChange(of: dati.partiTotali) {
                partiRimaste = min(partiRimaste, dati.partiTotali)
            }
            .onChange(of: nomePulito) {
                proponiDaOmonimo()
            }
            .onChange(of: marcaPulita) {
                proponiDaOmonimo()
            }
            .sheet(isPresented: $mostraNuovaCategoria) {
                CategoriaFormView(dispensa: dispensa) { nuova in
                    categoria = nuova
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
#endif
    }

    private var modulo: some View {
        Form {
            if articolo == nil {
                sezioneCodice
            }
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
    }

    private var sezioneCodice: some View {
        Section {
            TextField("Codice a barre", text: $codice, prompt: Text("Codice a barre o QR"))
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
                .onSubmit { usa(codice) }
            if ScannerCodici.disponibile {
                Button("Scansiona codice", systemImage: "barcode.viewfinder") { mostraScanner = true }
            }
        } header: {
            Text("Codice a barre")
        } footer: {
            if !codicePulito.isEmpty {
                if let prodotto = prodottoDelCodice {
                    if prodotto === prodottoEsistente {
                        Text("Prodotto riconosciuto dal codice.")
                    } else {
                        Text("Il codice è di «\(prodotto.nomeConMarca)»: non verrà collegato a un altro prodotto.")
                    }
                } else {
                    Text("Codice nuovo: verrà collegato al prodotto.")
                }
            }
        }
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
                    Label {
                        VStack(alignment: .leading) {
                            Text(prodotto.nomeConMarca)
                            if let categoria = prodotto.categoria {
                                Text(categoria.percorsoTestuale)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "arrow.up.left")
                    }
                }
            }
            TextField("Marca", text: $marca, prompt: Text("Marca (facoltativa)"))
            if prodottoNuovo {
                PickerCategoria(
                    titolo: "Categoria",
                    selezione: $categoria,
                    categorie: dispensa.categorieInOrdine,
                    etichettaNessuna: "Nessuna"
                )
                Button("Nuova categoria…", systemImage: "plus") { mostraNuovaCategoria = true }
            }
        } header: {
            Text("Prodotto")
        } footer: {
            if prodottoNuovo {
                if marcaPulita.isEmpty {
                    Text("Verrà creato il nuovo prodotto «\(nomePulito)».")
                } else {
                    Text("Verrà creato il nuovo prodotto «\(nomePulito)» (\(marcaPulita)).")
                }
            } else if let categoria = prodottoEsistente?.categoria {
                Text("Categoria: \(categoria.percorsoTestuale)")
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
            if prodottoNuovo, dati.partiTotali > 1 {
                Picker("Tipo di parte", selection: $tipoParte) {
                    Text("Non indicato").tag(nil as TipoParte?)
                    ForEach(TipoParte.allCases) { tipo in
                        Text(tipo.nomeSingolare).tag(tipo as TipoParte?)
                    }
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
            RigaDataFacoltativa("Produzione", data: $dati.dataProduzione)
            RigaDataFacoltativa("Scadenza", data: $dati.dataScadenza)
        }
    }

    /// Un codice letto o scritto: se è di un prodotto lo sceglie, altrimenti si passa a scrivere il nome.
    private func usa(_ letto: String) {
        codice = letto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !codicePulito.isEmpty else { return }
        if let prodotto = prodottoDelCodice {
            scegli(prodotto)
        } else if nomePulito.isEmpty {
            nomeInModifica = true
        }
    }

    /// Sceglie un prodotto suggerito; per un nuovo articolo propone i valori della sua confezione.
    private func scegli(_ prodotto: Prodotto) {
        nomeProdotto = prodotto.nome
        marca = prodotto.marca ?? ""
        nomeInModifica = false
        if articolo == nil {
            var proposti = DatiArticolo(prodotto: prodotto)
            proposti.dataInserimento = dati.dataInserimento
            proposti.dataProduzione = dati.dataProduzione
            proposti.dataScadenza = dati.dataScadenza
            dati = proposti
        }
    }

    /// Per un prodotto nuovo con lo stesso nome di uno esistente (es. un'altra marca),
    /// propone la sua categoria e il suo tipo di parte.
    private func proponiDaOmonimo() {
        guard prodottoNuovo, let omonimo = dispensa.prodottoOmonimo(nominato: nomePulito) else { return }
        categoria = omonimo.categoria
        tipoParte = omonimo.tipoParte
    }

    private func salva() {
        guard let struttura else { return }
        if let quantita = dati.quantitaPerParte, quantita <= 0 {
            dati.quantitaPerParte = nil
        }
        let prodotto = modelContext.trovaOCreaProdotto(
            nominato: nomePulito,
            marca: marcaPulita,
            in: dispensa,
            dati: dati,
            categoria: categoria,
            tipoParte: tipoParte
        )
        if let articolo {
            dati.applica(a: articolo)
            articolo.partiRimaste = min(partiRimaste, dati.partiTotali)
            articolo.prodotto = prodotto
            articolo.struttura = struttura
        } else {
            modelContext.aggiungiArticoli(dati, prodotto: prodotto, struttura: struttura, confezioni: confezioni)
            // Un codice nuovo si collega al prodotto; uno già di un altro prodotto resta dov'è.
            modelContext.aggiungiCodice(codicePulito, a: prodotto)
        }
        dismiss()
    }
}

#Preview {
    let struttura = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Struttura>(sortBy: [SortDescriptor(\.nome)])).first!
    ArticoloFormView(dispensa: struttura.dispensa!, struttura: struttura)
        .modelContainer(.anteprima)
}
