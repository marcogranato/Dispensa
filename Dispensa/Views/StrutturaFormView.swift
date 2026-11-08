//
//  StrutturaFormView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Modulo per creare una nuova struttura (`struttura == nil`) o modificarne una esistente.
/// Le modifiche vengono applicate solo premendo "Salva".
struct StrutturaFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dispensa: Dispensa
    let struttura: Struttura?

    @State private var nome: String
    @State private var tipo: TipoStruttura
    @State private var tipoPersonalizzato: String
    @State private var ubicazione: Ubicazione?
    /// 0 significa "non indicato".
    @State private var numeroRipiani: Int
    @State private var numeroCassetti: Int
    @State private var note: String

    init(dispensa: Dispensa, struttura: Struttura? = nil) {
        self.dispensa = dispensa
        self.struttura = struttura
        _nome = State(initialValue: struttura?.nome ?? "")
        _tipo = State(initialValue: struttura?.tipo ?? .frigorifero)
        _tipoPersonalizzato = State(initialValue: struttura?.tipoPersonalizzato ?? "")
        _ubicazione = State(initialValue: struttura?.ubicazione)
        _numeroRipiani = State(initialValue: struttura?.numeroRipiani ?? 0)
        _numeroCassetti = State(initialValue: struttura?.numeroCassetti ?? 0)
        _note = State(initialValue: struttura?.note ?? "")
    }

    private var ubicazioni: [Ubicazione] {
        (dispensa.ubicazioni ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
    }

    private var tipoPersonalizzatoPulito: String {
        tipoPersonalizzato.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Nome della tipologia, usato anche come nome della struttura se il campo nome è vuoto.
    private var nomeTipo: String {
        if tipo == .altro, !tipoPersonalizzatoPulito.isEmpty {
            return tipoPersonalizzatoPulito
        }
        return String(localized: tipo.nomeLocalizzato)
    }

    private var nomeEffettivo: String {
        let nomePulito = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        return nomePulito.isEmpty ? nomeTipo : nomePulito
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(TipoStruttura.allCases) { tipo in
                            Label { Text(tipo.nomeLocalizzato) } icon: { Image(systemName: tipo.simbolo) }
                                .tag(tipo)
                        }
                    }
                    if tipo == .altro {
                        TextField("Tipo personalizzato", text: $tipoPersonalizzato, prompt: Text("Es. Credenza, Cantinetta"))
                    }
                    TextField("Nome", text: $nome, prompt: Text(nomeTipo))
                } footer: {
                    Text("Se non indichi un nome, viene usato il tipo.")
                }

                Section {
                    Picker("Ubicazione", selection: $ubicazione) {
                        Text("Nessuna").tag(nil as Ubicazione?)
                        ForEach(ubicazioni) { ubicazione in
                            Text(ubicazione.nome).tag(ubicazione as Ubicazione?)
                        }
                    }
                } footer: {
                    if ubicazioni.isEmpty {
                        Text("Puoi creare le ubicazioni con il pulsante Ubicazioni nell'elenco delle strutture.")
                    }
                }

                Section("Caratteristiche") {
                    stepperFacoltativo("Ripiani", valore: $numeroRipiani)
                    stepperFacoltativo("Cassetti", valore: $numeroCassetti)
                }

                Section("Note") {
                    TextField("Note", text: $note, prompt: Text("Facoltative"), axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(struttura == nil ? Text("Nuova struttura") : Text("Modifica struttura"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", action: salva)
                        .disabled(nomeEffettivo.isEmpty)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
#endif
    }

    private func stepperFacoltativo(_ titolo: LocalizedStringKey, valore: Binding<Int>) -> some View {
        Stepper(value: valore, in: 0...50) {
            LabeledContent(titolo) {
                if valore.wrappedValue == 0 {
                    Text("Non indicato")
                } else {
                    Text(valore.wrappedValue, format: .number)
                }
            }
        }
    }

    private func salva() {
        let strutturaDaSalvare = struttura ?? {
            let nuova = Struttura(nome: nomeEffettivo, tipo: tipo)
            modelContext.insert(nuova)
            nuova.dispensa = dispensa
            return nuova
        }()
        let notePulite = note.trimmingCharacters(in: .whitespacesAndNewlines)
        strutturaDaSalvare.nome = nomeEffettivo
        strutturaDaSalvare.tipo = tipo
        strutturaDaSalvare.tipoPersonalizzato = tipo == .altro && !tipoPersonalizzatoPulito.isEmpty ? tipoPersonalizzatoPulito : nil
        strutturaDaSalvare.ubicazione = ubicazione
        strutturaDaSalvare.numeroRipiani = numeroRipiani == 0 ? nil : numeroRipiani
        strutturaDaSalvare.numeroCassetti = numeroCassetti == 0 ? nil : numeroCassetti
        strutturaDaSalvare.note = notePulite.isEmpty ? nil : notePulite
        dismiss()
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    StrutturaFormView(dispensa: dispensa)
        .modelContainer(.anteprima)
}
