//
//  RigaDataFacoltativa.swift
//  Dispensa
//

import SwiftUI

/// Data facoltativa su una sola riga: "Aggiungi" se manca, altrimenti il selettore e un pulsante per toglierla.
/// Usata nel modulo dell'articolo e nei filtri.
struct RigaDataFacoltativa: View {
    let titolo: LocalizedStringKey
    @Binding var data: Date?

    init(_ titolo: LocalizedStringKey, data: Binding<Date?>) {
        self.titolo = titolo
        _data = data
    }

    var body: some View {
        if let valore = data {
            HStack {
                DatePicker(
                    titolo,
                    selection: Binding(get: { valore }, set: { data = $0 }),
                    displayedComponents: .date
                )
                Button("Rimuovi data", systemImage: "xmark.circle.fill") {
                    data = nil
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .buttonStyle(.borderless)
            }
        } else {
            LabeledContent(titolo) {
                Button("Aggiungi") {
                    data = Calendar.current.startOfDay(for: .now)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
