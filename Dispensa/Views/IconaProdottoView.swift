//
//  IconaProdottoView.swift
//  Dispensa
//

import SwiftUI

/// Emoji di un prodotto davanti al nome nelle righe; senza emoji un simbolo neutro, così i nomi restano allineati.
/// È nascosta a VoiceOver: il nome basta a identificare la riga.
struct IconaProdottoView: View {
    let icona: String?

    var body: some View {
        Group {
            if let icona {
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
