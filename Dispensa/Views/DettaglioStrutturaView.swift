//
//  DettaglioStrutturaView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Riepilogo delle caratteristiche di una struttura.
struct DettaglioStrutturaView: View {
    let struttura: Struttura

    @State private var mostraModifica = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Tipo") {
                    HStack {
                        Image(systemName: struttura.tipo.simbolo)
                        Text(struttura.nomeTipo)
                    }
                }
                LabeledContent("Ubicazione") {
                    if let ubicazione = struttura.ubicazione {
                        Text(ubicazione.nome)
                    } else {
                        Text("Nessuna")
                    }
                }
                if let numeroRipiani = struttura.numeroRipiani {
                    LabeledContent("Ripiani") { Text(numeroRipiani, format: .number) }
                }
                if let numeroCassetti = struttura.numeroCassetti {
                    LabeledContent("Cassetti") { Text(numeroCassetti, format: .number) }
                }
            }

            if let note = struttura.note {
                Section("Note") {
                    Text(note)
                }
            }

            Section("Articoli") {
                LabeledContent("Presenti") {
                    Text(struttura.articoliAttivi.count, format: .number)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(struttura.nome)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifica") { mostraModifica = true }
            }
        }
        .sheet(isPresented: $mostraModifica) {
            if let dispensa = struttura.dispensa {
                StrutturaFormView(dispensa: dispensa, struttura: struttura)
            }
        }
    }
}

#Preview {
    let struttura = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Struttura>(sortBy: [SortDescriptor(\.nome)])).first!
    NavigationStack {
        DettaglioStrutturaView(struttura: struttura)
    }
    .modelContainer(.anteprima)
}
