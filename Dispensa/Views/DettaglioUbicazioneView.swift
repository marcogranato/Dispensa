//
//  DettaglioUbicazioneView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Scheda di un'ubicazione: le strutture che contiene, con Rinomina ed Elimina.
struct DettaglioUbicazioneView: View {
    @Environment(\.dismiss) private var dismiss

    let ubicazione: Ubicazione

    @State private var nome: NomeUbicazione?
    @State private var ubicazioneDaEliminare: Ubicazione?
    @State private var mostraNuovaStruttura = false

    private var eliminata: Bool {
        ubicazione.isDeleted || ubicazione.modelContext == nil
    }

    var body: some View {
        Group {
            if eliminata {
                ContentUnavailableView("Ubicazione eliminata", systemImage: "mappin.and.ellipse")
            } else {
                contenuto
            }
        }
        .onChange(of: eliminata) {
            if eliminata { dismiss() }
        }
    }

    private var contenuto: some View {
        let strutture = (ubicazione.strutture ?? []).sorted { $0.nome.localizedStandardCompare($1.nome) == .orderedAscending }
        return Form {
            Section {
                ForEach(strutture) { struttura in
                    RigaNavigabile(valore: struttura) {
                        RigaStrutturaView(struttura: struttura)
                    }
                }
                Button("Aggiungi struttura", systemImage: "plus.circle") { mostraNuovaStruttura = true }
            } header: {
                Text("Strutture: \(strutture.count)")
            } footer: {
                if strutture.isEmpty {
                    Text("Per spostare qui una struttura esistente cambia l'ubicazione nella sua scheda.")
                }
            }

            Section {
                Button("Elimina ubicazione", systemImage: "trash", role: .destructive) {
                    ubicazioneDaEliminare = ubicazione
                }
                .tint(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(ubicazione.nome)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Rinomina") { nome = .rinomina(ubicazione) }
            }
        }
        .sheet(isPresented: $mostraNuovaStruttura) {
            if let dispensa = ubicazione.dispensa {
                StrutturaFormView(dispensa: dispensa, ubicazione: ubicazione)
            }
        }
        .nomeUbicazione($nome, dispensa: ubicazione.dispensa)
        .eliminazioneUbicazione($ubicazioneDaEliminare)
    }
}

#Preview {
    let ubicazione = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Ubicazione>()).first!
    PilaDiNavigazione {
        DettaglioUbicazioneView(ubicazione: ubicazione)
    }
    .modelContainer(.anteprima)
}
