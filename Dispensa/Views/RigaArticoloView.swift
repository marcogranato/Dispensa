//
//  RigaArticoloView.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Riga di un articolo negli elenchi: a sinistra l'icona, centrata; accanto nome, marca, parti e quantità,
/// scadenza evidenziata e, sotto, la struttura (quando serve), allineata al nome.
struct RigaArticoloView: View {
    let articolo: Articolo
    /// Il nome della struttura, per gli elenchi con articoli di più strutture.
    var struttura: String?

    private var dettagli: String? {
        let parti = articolo.partiTotali > 1
            ? String(localized: "\(articolo.partiRimaste) di \(articolo.partiTotali)")
            : nil
        let quantita = Formattazione.quantita(articolo.quantitaPerParte, unita: articolo.unita)
        // La marca distingue articoli dello stesso prodotto di marche diverse (es. Penne rigate Barilla e De Cecco).
        let testo = [articolo.prodotto?.marca, parti, quantita].compactMap { $0 }.joined(separator: " · ")
        return testo.isEmpty ? nil : testo
    }

    var body: some View {
        ImpaginazioneRigaArticolo(
            prodotto: articolo.prodotto,
            nome: articolo.nomeVisualizzato,
            dettagli: dettagli,
            sottotitolo: struttura
        ) {
            if let data = articolo.dataScadenza {
                EtichettaScadenzaView(data: data, stato: articolo.statoScadenza())
                    .font(.caption)
            }
        }
    }
}

/// Riga di più confezioni dello stesso prodotto: "Gran Cereale frutta ×3", la scadenza più vicina
/// con il colore del caso peggiore e, sotto, le strutture in cui si trovano.
struct RigaGruppoArticoliView: View {
    let gruppo: GruppoArticoli
    /// Mostra sotto il nome le strutture (per gli elenchi di più strutture).
    var mostraStruttura = false

    private var dettagli: String? {
        let articoli = gruppo.articoli
        // La quantità per parte si mostra solo se è uguale in tutte le confezioni.
        let quantite = Set(articoli.map { Formattazione.quantita($0.quantitaPerParte, unita: $0.unita) })
        let quantita = quantite.count == 1 ? quantite.first ?? nil : nil
        var parti: String?
        if gruppo.conPiuParti {
            let nome = gruppo.prodotto?.tipoParte.map { String(localized: $0.nomePlurale) } ?? String(localized: "parti")
            parti = String(localized: "\(gruppo.partiRimaste) \(nome)")
        }
        let testo = [gruppo.prodotto?.marca, parti, quantita].compactMap { $0 }.joined(separator: " · ")
        return testo.isEmpty ? nil : testo
    }

    private var strutture: String? {
        guard mostraStruttura else { return nil }
        let nomi = gruppo.strutture
        if nomi.isEmpty { return nil }
        if nomi.count <= 2 { return nomi.joined(separator: ", ") }
        return String(localized: "\(nomi.count) strutture")
    }

    var body: some View {
        ImpaginazioneRigaArticolo(
            prodotto: gruppo.prodotto,
            nome: gruppo.articoli[0].nomeVisualizzato,
            dettagli: dettagli,
            confezioni: gruppo.confezioni,
            sottotitolo: strutture
        ) {
            if let data = gruppo.scadenzaPiuVicina {
                EtichettaScadenzaView(data: data, stato: gruppo.statoPeggiore())
                    .font(.caption)
            }
        }
    }
}

/// L'impaginazione comune alle righe di articoli e di gruppi: icona centrata a sinistra; nome, dettagli,
/// numero di confezioni e scadenza su una riga (su due se non ci stanno); sotto, il sottotitolo allineato al nome.
private struct ImpaginazioneRigaArticolo<Scadenza: View>: View {
    let prodotto: Prodotto?
    let nome: String
    let dettagli: String?
    /// "×3" per un gruppo di confezioni.
    var confezioni: Int?
    var sottotitolo: String?
    @ViewBuilder let scadenza: Scadenza

    var body: some View {
        HStack(spacing: 12) {
            IconaProdottoView(icona: prodotto?.iconaEffettiva, miniatura: prodotto?.miniatura)
            VStack(alignment: .leading, spacing: 2) {
                // Prima prova nome, dettagli e scadenza su una riga; se non ci stanno (nome lungo, testo grande)
                // i dettagli vanno sotto il nome.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(nome)
                            .lineLimit(1)
                            .fixedSize()
                        if let dettagli {
                            testoDettagli(dettagli)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        Spacer(minLength: 8)
                        numeroConfezioni
                            .fixedSize()
                        scadenza
                            .fixedSize()
                    }
                    HStack {
                        VStack(alignment: .leading) {
                            Text(nome)
                            if let dettagli {
                                testoDettagli(dettagli)
                            }
                        }
                        Spacer()
                        numeroConfezioni
                        scadenza
                    }
                }
                if let sottotitolo {
                    Text(sottotitolo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // La linea tra le righe parte dal testo, uguale per tutte le righe.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }

    private func testoDettagli(_ testo: String) -> some View {
        Text(testo)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var numeroConfezioni: some View {
        if let confezioni {
            Text("×\(confezioni)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
                .accessibilityLabel(Text("\(confezioni) confezioni"))
        }
    }
}

/// Data di scadenza colorata, con icona per gli articoli scaduti o in scadenza.
struct EtichettaScadenzaView: View {
    let data: Date
    let stato: StatoScadenza

    var body: some View {
        let testoData = data.formatted(date: .abbreviated, time: .omitted)
        Group {
            switch stato {
            case .scaduto:
                Label(testoData, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel(Text("Scaduto il \(testoData)"))
            case .inScadenza:
                Label(testoData, systemImage: "clock")
                    .foregroundStyle(.orange)
                    .accessibilityLabel(Text("In scadenza il \(testoData)"))
            case .valido, .senzaScadenza:
                Text(testoData)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("Scade il \(testoData)"))
            }
        }
        .labelStyle(.titleAndIcon)
    }
}
