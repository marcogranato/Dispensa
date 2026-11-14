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
    @State private var codiceBarre: String
    @State private var partiPerConfezione: Int
    @State private var tipoParte: TipoParte?
    @State private var quantitaPerParte: Double?
    @State private var unita: Unita?
    @State private var descrizione: String
    @State private var note: String

    init(dispensa: Dispensa, prodotto: Prodotto? = nil) {
        self.dispensa = dispensa
        self.prodotto = prodotto
        _nome = State(initialValue: prodotto?.nome ?? "")
        _categoria = State(initialValue: prodotto?.categoria)
        _marca = State(initialValue: prodotto?.marca ?? "")
        _icona = State(initialValue: prodotto?.icona ?? "")
        _codiceBarre = State(initialValue: prodotto?.codiceBarre ?? "")
        _partiPerConfezione = State(initialValue: prodotto?.partiPerConfezione ?? 1)
        _tipoParte = State(initialValue: prodotto?.tipoParte)
        _quantitaPerParte = State(initialValue: prodotto?.quantitaPerParte)
        _unita = State(initialValue: prodotto?.unita)
        _descrizione = State(initialValue: prodotto?.descrizione ?? "")
        _note = State(initialValue: prodotto?.note ?? "")
    }

    private var nomePulito: String {
        nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var multipack: Bool { partiPerConfezione > 1 }

    /// Es. "400 g" per 4 parti da 100 g; `nil` se non serve mostrarla.
    private var quantitaTotale: String? {
        guard multipack, let quantitaPerParte, quantitaPerParte > 0 else { return nil }
        return Formattazione.quantita(quantitaPerParte * Double(partiPerConfezione), unita: unita)
    }

    var body: some View {
        NavigationStack {
            Form {
                sezioneIdentificazione
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
                        .disabled(nomePulito.isEmpty)
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
            TextField("Emoji", text: $icona, prompt: Text("Emoji (facoltativa)"))
                .onChange(of: icona) { _, nuovo in
                    let ridotta = Categoria.iconaNormalizzata(nuovo) ?? ""
                    if ridotta != nuovo { icona = ridotta }
                }
            TextField("Codice a barre", text: $codiceBarre, prompt: Text("Codice a barre o QR (facoltativo)"))
                .autocorrectionDisabled()
#if os(iOS)
                .textInputAutocapitalization(.never)
#endif
        } header: {
            Text("Identificazione e classificazione")
        } footer: {
            if icona.isEmpty, let ereditata = categoria?.iconaEffettiva {
                Text("Senza emoji si usa quella della categoria: \(ereditata). La lettura del codice con la fotocamera arriverà in seguito.")
            } else {
                Text("La lettura del codice con la fotocamera arriverà in seguito.")
            }
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
        prodottoDaSalvare.codiceBarre = Self.testoFacoltativo(codiceBarre)
        prodottoDaSalvare.partiPerConfezione = partiPerConfezione
        // Il tipo di parte conta solo per le confezioni con più parti.
        prodottoDaSalvare.tipoParte = multipack ? tipoParte : nil
        prodottoDaSalvare.quantitaPerParte = quantitaPerParte.flatMap { $0 > 0 ? $0 : nil }
        prodottoDaSalvare.unita = unita
        prodottoDaSalvare.descrizione = Self.testoFacoltativo(descrizione)
        prodottoDaSalvare.note = Self.testoFacoltativo(note)
        dismiss()
    }

    /// Testo ripulito dagli spazi; `nil` se vuoto.
    private static func testoFacoltativo(_ testo: String) -> String? {
        let pulito = testo.trimmingCharacters(in: .whitespacesAndNewlines)
        return pulito.isEmpty ? nil : pulito
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    ProdottoFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
