//
//  IconaProdottoView.swift
//  Dispensa
//

import SwiftUI

/// Foto (miniatura) o emoji di un prodotto davanti al nome nelle righe; senza emoji un simbolo neutro, così i nomi restano allineati.
/// È nascosta a VoiceOver: il nome basta a identificare la riga.
struct IconaProdottoView: View {
    let icona: String?
    /// La miniatura della foto del prodotto: se c'è, prende il posto dell'emoji.
    var miniatura: Data?

    var body: some View {
        Group {
            if let miniatura {
                MiniaturaView(dati: miniatura)
            } else if let icona {
                Text(icona)
            } else {
                Image(systemName: "shippingbox")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 24)
        .accessibilityHidden(true)
    }
}
