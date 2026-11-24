//
//  ProdottoFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare un nuovo prodotto (`prodotto == nil`) o modificarne uno esistente.
/// Le modifiche vengono applicate solo premendo "Salva". Solo il nome è obbligatorio.
struct ProdottoFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let prodotto: Prodotto?

    @State private var nome: String
    @State private var categoria: Categoria?
    @State private var marca: String
    @State private var icona: String
    @State private var codici: [CampoCodice]
    /// Il campo del codice appena letto che c'era già: si evidenzia per un attimo.
    @State private var codiceEvidenziato: CampoCodice.ID?
    @State private var partiPerConfezione: Int
    @State private var tipoParte: TipoParte?
    @State private var quantitaPerParte: Double?
    @State private var unita: Unita?
    @State private var descrizione: String
    @State private var note: String
    @State private var etichette: Set<UUID>
    @State private var immagine: ImmagineElaborata?
    /// L'immagine all'apertura: si riscrive solo se cambia.
    private let immagineIniziale: ImmagineElaborata?

    init(dispensa: Dispensa, prodotto: Prodotto? = nil) {
        self.dispensa = dispensa
        self.prodotto = prodotto
        _nome = State(initialValue: prodotto?.nome ?? "")
        _categoria = State(initialValue: prodotto?.categoria)
        _marca = State(initialValue: prodotto?.marca ?? "")
        _icona = State(initialValue: prodotto?.icona ?? "")
        // Un campo vuoto pronto per il primo codice.
        let salvati = prodotto?.codiciOrdinati ?? []
        _codici = State(initialValue: (salvati.isEmpty ? [""] : salvati).map(CampoCodice.init))
        _partiPerConfezione = State(initialValue: prodotto?.partiPerConfezione ?? 1)
        _tipoParte = State(initialValue: prodotto?.tipoParte)
        _quantitaPerParte = State(initialValue: prodotto?.quantitaPerParte)
        _unita = State(initialValue: prodotto?.unita)
        _descrizione = State(initialValue: prodotto?.descrizione ?? "")
        _note = State(initialValue: prodotto?.note ?? "")
        _etichette = State(initialValue: Set((prodotto?.etichette ?? []).map(\.id)))
        immagineIniziale = ImmagineElaborata(salvata: prodotto?.immagine, miniatura: prodotto?.miniatura)
        _immagine = State(initialValue: immagineIniziale)
    }

    private var nomePulito: String {
        nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var multipack: Bool { partiPerConfezione > 1 }

    /// Un altro prodotto con lo stesso nome e la stessa marca: non se ne possono avere due.
    private var duplicato: Prodotto? {
        guard let trovato = dispensa.prodotto(nominato: nomePulito, marca: marca), trovato !== prodotto else { return nil }
        return trovato
    }

    /// Un codice scritto qui che appartiene già a un altro prodotto: non si può salvare.
    private var codiceUsato: (codice: String, prodotto: Prodotto)? {
        dispensa.codiceGiaUsato(tra: codici.map(\.testo), escluso: prodotto)
    }

    /// Es. "400 g" per 4 parti da 100 g; `nil` se non serve mostrarla.
    private var quantitaTotale: String? {
        guard multipack, let quantitaPerParte, quantitaPerParte > 0 else { return nil }
        return Formattazione.quantita(quantitaPerParte * Double(partiPerConfezione), unita: unita)
    }

    var body: some View {
        NavigationStack {
            Form {
                sezioneIdentificazione
                SezioneImmagine(immagine: $immagine)
                sezioneCodici
                sezioneEtichette
                sezioneQuantita
                sezioneConfezionamento
                sezioneAltreInformazioni
            }
            .formStyle(.grouped)
            .navigationTitle(prodotto == nil ? Text("Nuovo prodotto") : Text("Modifica prodotto"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nomePulito.isEmpty || duplicato != nil || codiceUsato != nil)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 440, minHeight: 560)
#endif
    }

    // MARK: - Sezioni

    private var sezioneIdentificazione: some View {
        Section {
            TextField("Nome", text: $nome, prompt: Text("Es. Penne rigate, Latte, Acqua"))
            PickerCategoria(
                titolo: "Categoria",
                selezione: $categoria,
                categorie: dispensa.categorieInOrdine,
                etichettaNessuna: "Nessuna"
            )
            TextField("Marca", text: $marca, prompt: Text("Marca (facoltativa)"))
            SelettoreEmoji(titolo: "Emoji", selezione: $icona, ereditata: categoria?.iconaEffettiva)
        } header: {
            Text("Identificazione e classificazione")
        } footer: {
            if let duplicato {
                Label("Esiste già il prodotto «\(duplicato.nomeConMarca)». Cambia il nome o la marca.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            } else if icona.isEmpty, let ereditata = categoria?.iconaEffettiva {
                Text("Senza emoji si usa quella della categoria: \(ereditata).")
            }
        }
    }

    private var sezioneCodici: some View {
        Section {
            ForEach($codici) { $campo in
                HStack {
                    TextField("Codice a barre", text: $campo.testo, prompt: Text("Codice a barre o QR"))
                        .autocorrectionDisabled()
#if os(iOS)
                        .textInputAutocapitalization(.never)
#endif
                    if codici.count > 1 || !campo.testo.isEmpty {
                        Button("Togli codice", systemImage: "minus.circle.fill") {
                            togli(campo)
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.red)
                        .buttonStyle(.borderless)
                    }
                }
                .listRowBackground(codiceEvidenziato == campo.id ? Color.yellow.opacity(0.3) : nil)
            }
            PulsanteScansione(letto: inserisci)
            Button("Aggiungi codice", systemImage: "plus.circle") {
                codici.append(CampoCodice(""))
            }
        } header: {
            Text("Codici a barre")
        } footer: {
            if let codiceUsato {
                Label(
                    "Il codice \(codiceUsato.codice) è già del prodotto «\(codiceUsato.prodotto.nomeConMarca)».",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.red)
            } else {
                Text("Facoltativi. Uno stesso prodotto può averne più d'uno (es. confezione singola e multipla).")
            }
        }
    }

    /// Mette il codice letto dallo scanner nel primo campo vuoto o in fondo; se c'è già, lo evidenzia.
    private func inserisci(_ letto: String) {
        switch Codici.posizione(del: letto, in: codici.map(\.testo)) {
        case .giaPresente(let indice):
            let id = codici[indice].id
            codiceEvidenziato = id
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                if codiceEvidenziato == id { codiceEvidenziato = nil }
            }
        case .campoVuoto(let indice):
            codici[indice].testo = letto
        case .inFondo:
            codici.append(CampoCodice(letto))
        }
    }

    /// Toglie un codice; se era l'unico, svuota il campo.
    private func togli(_ campo: CampoCodice) {
        if codici.count > 1 {
            codici.removeAll { $0.id == campo.id }
        } else {
            codici = [CampoCodice("")]
        }
    }

    private var sezioneEtichette: some View {
        Section {
            SelettoreEtichette(dispensa: dispensa, selezione: $etichette)
        } header: {
            Text("Etichette")
        }
    }

    private var sezioneQuantita: some View {
        Section {
            LabeledContent(multipack ? "Quantità per parte" : "Quantità netta") {
                TextField("Quantità", value: $quantitaPerParte, format: .number, prompt: Text("Facoltativa"))
                    .multilineTextAlignment(.trailing)
                    .labelsHidden()
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            Picker("Unità", selection: $unita) {
                Text("Nessuna").tag(nil as Unita?)
                ForEach(Unita.allCases) { unita in
                    Text(unita.nomeLocalizzato).tag(unita as Unita?)
                }
            }
            if let quantitaTotale {
                LabeledContent("Quantità totale", value: quantitaTotale)
            }
        } header: {
            Text("Quantità e misura")
        }
    }

    private var sezioneConfezionamento: some View {
        Section {
            Stepper(value: $partiPerConfezione, in: 1...100) {
                LabeledContent("Parti per confezione") {
                    Text(partiPerConfezione, format: .number)
                }
            }
            if multipack {
                Picker("Tipo di parte", selection: $tipoParte) {
                    Text("Non indicato").tag(nil as TipoParte?)
                    ForEach(TipoParte.allCases) { tipo in
                        Text(tipo.nomeSingolare).tag(tipo as TipoParte?)
                    }
                }
            }
        } header: {
            Text("Confezionamento")
        } footer: {
            Text("Valori proposti quando aggiungi un articolo di questo prodotto. Es. una scatola di biscotti con 4 pacchetti da 100 g.")
        }
    }

    private var sezioneAltreInformazioni: some View {
        Section {
            TextField("Descrizione", text: $descrizione, prompt: Text("Descrizione (facoltativa)"), axis: .vertical)
                .lineLimit(1...5)
            TextField("Note personali", text: $note, prompt: Text("Note personali (facoltative)"), axis: .vertical)
                .lineLimit(1...5)
        } header: {
            Text("Altre informazioni")
        }
    }

    // MARK: - Salvataggio

    private func salva() {
        let prodottoDaSalvare = prodotto ?? {
            let nuovo = Prodotto(nome: nomePulito)
            modelContext.insert(nuovo)
            nuovo.dispensa = dispensa
            return nuovo
        }()
        prodottoDaSalvare.nome = nomePulito
        prodottoDaSalvare.categoria = categoria
        prodottoDaSalvare.marca = Self.testoFacoltativo(marca)
        prodottoDaSalvare.icona = Categoria.iconaNormalizzata(icona)
        // I codici già usati da altri prodotti sono controllati prima: "Salva" è disattivato.
        try? modelContext.impostaCodici(codici.map(\.testo), a: prodottoDaSalvare)
        prodottoDaSalvare.partiPerConfezione = partiPerConfezione
        // Il tipo di parte conta solo per le confezioni con più parti.
        prodottoDaSalvare.tipoParte = multipack ? tipoParte : nil
        prodottoDaSalvare.quantitaPerParte = quantitaPerParte.flatMap { $0 > 0 ? $0 : nil }
        prodottoDaSalvare.unita = unita
        prodottoDaSalvare.descrizione = Self.testoFacoltativo(descrizione)
        prodottoDaSalvare.note = Self.testoFacoltativo(note)
        prodottoDaSalvare.etichette = dispensa.etichetteOrdinate.filter { etichette.contains($0.id) }
        if immagine != immagineIniziale {
            prodottoDaSalvare.immagine = immagine?.immagine
            prodottoDaSalvare.miniatura = immagine?.miniatura
        }
        dismiss()
    }

    /// Testo ripulito dagli spazi; `nil` se vuoto.
    private static func testoFacoltativo(_ testo: String) -> String? {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        return pulito.isEmpty ? nil : pulito
    }
}

/// Un campo del modulo per un codice a barre (con un id, per poterlo togliere dall'elenco).
private struct CampoCodice: Identifiable {
    let id = UUID()
    var testo: String

    init(_ testo: String) {
        self.testo = testo
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    ProdottoFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
