//
//  DettaglioArticoloView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Tutte le informazioni di un articolo, con le azioni disponibili.
struct DettaglioArticoloView: View {
    @Environment(\.dismiss) private var dismiss

    let articolo: Articolo

    @State private var azione: AzioneArticolo?
    @State private var daEliminare: Articolo?

    /// Vero quando l'articolo è uscito dalla dispensa o è stato eliminato.
    private var nonPiuPresente: Bool {
        articolo.isDeleted || articolo.modelContext == nil || articolo.stato != .attivo
    }

    var body: some View {
        Group {
            if nonPiuPresente {
                ContentUnavailableView("Articolo non più in dispensa", systemImage: "checkmark.circle")
            } else {
                contenuto
            }
        }
        .onChange(of: nonPiuPresente) {
            if nonPiuPresente { dismiss() }
        }
    }

    private var contenuto: some View {
        Form {
            Section {
                LabeledContent("Struttura") {
                    if let struttura = articolo.struttura {
                        Text(struttura.nome)
                    } else {
                        Text("Nessuna")
                    }
                }
                if articolo.partiTotali > 1 {
                    LabeledContent("Parti") {
                        Text("\(articolo.partiRimaste) di \(articolo.partiTotali)")
                    }
                }
                if let quantita = Formattazione.quantita(articolo.quantitaPerParte, unita: articolo.unita) {
                    LabeledContent("Quantità per parte", value: quantita)
                }
                if articolo.partiButtate > 0 {
                    LabeledContent("Parti buttate") {
                        Text(articolo.partiButtate, format: .number)
                    }
                }
            }

            Section("Date") {
                LabeledContent("Inserimento") {
                    Text(articolo.dataInserimento, format: .dateTime.day().month().year())
                }
                if let produzione = articolo.dataProduzione {
                    LabeledContent("Produzione") {
                        Text(produzione, format: .dateTime.day().month().year())
                    }
                }
                LabeledContent("Scadenza") {
                    if let scadenza = articolo.dataScadenza {
                        EtichettaScadenzaView(data: scadenza, stato: articolo.statoScadenza())
                    } else {
                        Text("Non indicata")
                    }
                }
            }

            Section {
                Button("Preleva…", systemImage: "minus.circle") { azione = AzioneArticolo(tipo: .preleva, articolo: articolo) }
                Button("Butta…", systemImage: "trash.slash") { azione = AzioneArticolo(tipo: .butta, articolo: articolo) }
                Button("Sposta…", systemImage: "arrow.right.circle") { azione = AzioneArticolo(tipo: .sposta, articolo: articolo) }
            }

            Section {
                Button("Elimina articolo", systemImage: "trash", role: .destructive) { daEliminare = articolo }
                    .tint(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(articolo.nomeVisualizzato)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifica") { azione = AzioneArticolo(tipo: .modifica, articolo: articolo) }
            }
        }
        .azioniArticolo($azione, daEliminare: $daEliminare)
    }
}

#Preview {
    let articolo = try! ModelContainer.anteprima.mainContext.fetch(FetchDescriptor<Articolo>()).first!
    PilaDiNavigazione {
        DettaglioArticoloView(articolo: articolo)
    }
    .modelContainer(.anteprima)
}
