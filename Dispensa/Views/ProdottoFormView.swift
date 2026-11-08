//
//  ProdottoFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare un nuovo prodotto (`prodotto == nil`) o modificarne uno esistente.
/// Le modifiche vengono applicate solo premendo "Salva".
struct ProdottoFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let prodotto: Prodotto?

    @State private var nome: String
    @State private var marca: String
    @State private var codiceBarre: String
    @State private var partiPerConfezione: Int
    @State private var quantitaPerParte: Double?
    @State private var unita: Unita?

    init(dispensa: Dispensa, prodotto: Prodotto? = nil) {
        self.dispensa = dispensa
        self.prodotto = prodotto
        _nome = State(initialValue: prodotto?.nome ?? "")
        _marca = State(initialValue: prodotto?.marca ?? "")
        _codiceBarre = State(initialValue: prodotto?.codiceBarre ?? "")
        _partiPerConfezione = State(initialValue: prodotto?.partiPerConfezione ?? 1)
        _quantitaPerParte = State(initialValue: prodotto?.quantitaPerParte)
        _unita = State(initialValue: prodotto?.unita)
    }

    private var nomePulito: String {
        nome.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $nome, prompt: Text("Es. Biscotti, Latte, Acqua"))
                    TextField("Marca", text: $marca, prompt: Text("Marca (facoltativa)"))
                }

                Section {
                    TextField("Codice a barre", text: $codiceBarre, prompt: Text("Codice a barre o QR (facoltativo)"))
                        .autocorrectionDisabled()
#if os(iOS)
                        .textInputAutocapitalization(.never)
#endif
                } footer: {
                    Text("La lettura con la fotocamera arriverà in seguito.")
                }

                Section {
                    Stepper(value: $partiPerConfezione, in: 1...100) {
                        LabeledContent("Parti per confezione") {
                            Text(partiPerConfezione, format: .number)
                        }
                    }
                    LabeledContent("Quantità per parte") {
                        TextField("Quantità per parte", value: $quantitaPerParte, format: .number, prompt: Text("Facoltativa"))
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
                } header: {
                    Text("Confezione")
                } footer: {
                    Text("Valori proposti quando aggiungi un articolo di questo prodotto. Es. una scatola di biscotti con 6 pacchi da 150 g.")
                }
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
        .frame(minWidth: 420, minHeight: 460)
#endif
    }

    private func salva() {
        let prodottoDaSalvare = prodotto ?? {
            let nuovo = Prodotto(nome: nomePulito)
            modelContext.insert(nuovo)
            nuovo.dispensa = dispensa
            return nuovo
        }()
        let marcaPulita = marca.trimmingCharacters(in: .whitespacesAndNewlines)
        let codicePulito = codiceBarre.trimmingCharacters(in: .whitespacesAndNewlines)
        prodottoDaSalvare.nome = nomePulito
        prodottoDaSalvare.marca = marcaPulita.isEmpty ? nil : marcaPulita
        prodottoDaSalvare.codiceBarre = codicePulito.isEmpty ? nil : codicePulito
        prodottoDaSalvare.partiPerConfezione = partiPerConfezione
        prodottoDaSalvare.quantitaPerParte = quantitaPerParte.flatMap { $0 > 0 ? $0 : nil }
        prodottoDaSalvare.unita = unita
        dismiss()
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    ProdottoFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
