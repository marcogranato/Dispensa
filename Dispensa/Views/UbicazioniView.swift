//
//  UbicazioniView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Valore di navigazione per aprire l'elenco delle ubicazioni di una dispensa (vedi `PilaDiNavigazione`).
struct ElencoUbicazioni: Hashable {
    let dispensa: Dispensa
}

/// Ubicazioni (cucina, cantina, …) di una dispensa, aperte dalla scheda Strutture.
/// Il clic su un'ubicazione apre la sua scheda; rinomina ed eliminazione anche da scorrimento e menu contestuale.
struct UbicazioniView: View {
    @Environment(\.modelContext) private var modelContext

    let dispensa: Dispensa

    @State private var nome: NomeUbicazione?
    @State private var ubicazioneDaEliminare: Ubicazione?

    private static let suggerimenti: [LocalizedStringResource] = [
        "Cucina", "Cantina", "Salone", "Ripostiglio", "Garage", "Taverna", "Giardino",
    ]

    private var suggerimentiDisponibili: [String] {
        Self.suggerimenti.map { String(localized: $0) }.filter { !dispensa.esisteUbicazione(nominata: $0) }
    }

    var body: some View {
        let ubicazioni = dispensa.ubicazioniOrdinate
        List {
            Section {
                ForEach(ubicazioni) { ubicazione in
                    RigaNavigabile(valore: ubicazione) {
                        RigaUbicazioneView(ubicazione: ubicazione)
                    }
                    .contextMenu {
                        pulsanteRinomina(ubicazione)
                        pulsanteElimina(ubicazione)
                    }
                    .swipeActions {
                        pulsanteElimina(ubicazione)
                        pulsanteRinomina(ubicazione)
                    }
                }
            } footer: {
                if ubicazioni.isEmpty {
                    Text("Nessuna ubicazione. Aggiungine una o scegli tra i suggerimenti.")
                }
            }

            if !suggerimentiDisponibili.isEmpty {
                Section("Suggerimenti") {
                    ForEach(suggerimentiDisponibili, id: \.self) { suggerimento in
                        Button {
                            modelContext.aggiungiUbicazione(nominata: suggerimento, in: dispensa)
                        } label: {
                            Label(suggerimento, systemImage: "plus.circle")
                        }
                    }
                }
            }
        }
        .navigationTitle("Ubicazioni")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nuova ubicazione", systemImage: "plus") { nome = .nuova }
            }
        }
        .nomeUbicazione($nome, dispensa: dispensa)
        .eliminazioneUbicazione($ubicazioneDaEliminare)
    }

    private func pulsanteRinomina(_ ubicazione: Ubicazione) -> some View {
        Button("Rinomina", systemImage: "pencil") { nome = .rinomina(ubicazione) }
            .tint(.accentColor)
    }

    private func pulsanteElimina(_ ubicazione: Ubicazione) -> some View {
        Button("Elimina", systemImage: "trash", role: .destructive) { ubicazioneDaEliminare = ubicazione }
    }
}

/// Riga di un'ubicazione: nome e numero di strutture.
struct RigaUbicazioneView: View {
    let ubicazione: Ubicazione

    var body: some View {
        let strutture = ubicazione.strutture?.count ?? 0
        HStack {
            Label(ubicazione.nome, systemImage: "mappin.and.ellipse")
                .foregroundStyle(.primary)
            Spacer()
            Text(strutture, format: .number)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(Text("Strutture: \(strutture)"))
        }
    }
}

#Preview {
    let dispensa = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Dispensa>(sortBy: [SortDescriptor(\.nome)])).first!
    PilaDiNavigazione {
        UbicazioniView(dispensa: dispensa)
    }
    .modelContainer(.anteprima)
}
