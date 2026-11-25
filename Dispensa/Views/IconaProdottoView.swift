//
//  IconaProdottoView.swift
//  Dispensa
//

import SwiftUI

/// Foto (miniatura) o emoji di un prodotto davanti al nome nelle righe; senza emoji un simbolo neutro.
/// Occupa sempre lo stesso quadrato, così i nomi di tutte le righe partono dallo stesso punto.
/// È nascosta a VoiceOver: il nome basta a identificare la riga.
struct IconaProdottoView: View {
    let icona: String?
    /// La miniatura della foto del prodotto: se c'è, prende il posto dell'emoji.
    var miniatura: Data?

    /// Cresce con la dimensione del testo scelta nelle impostazioni di sistema.
    @ScaledMetric(relativeTo: .body) private var lato: CGFloat = 34

    var body: some View {
        Group {
            if let miniatura {
                MiniaturaView(dati: miniatura, lato: lato)
            } else if let icona {
                Text(icona)
                    .font(.system(size: lato * 0.72))
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: lato * 0.55))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: lato, height: lato)
        .accessibilityHidden(true)
    }
}
