//
//  MenuOrdinamento.swift
//  Dispensa
//

import SwiftUI

/// Pulsante "Ordina" per la barra: sceglie il criterio e il verso dell'ordine di un elenco.
struct MenuOrdinamento<Criterio: CriterioOrdinamento>: View {
    let criteri: [Criterio]
    @Binding var ordine: Ordine<Criterio>

    var body: some View {
        Menu {
            Picker("Ordina per", selection: $ordine.criterio) {
                ForEach(criteri) { criterio in
                    Text(criterio.nomeLocalizzato).tag(criterio)
                }
            }
            .pickerStyle(.inline)
            Picker("Verso", selection: $ordine.crescente) {
                Text(ordine.criterio.nomeCrescente).tag(true)
                Text(ordine.criterio.nomeDecrescente).tag(false)
            }
            .pickerStyle(.inline)
        } label: {
            Label("Ordina", systemImage: "arrow.up.arrow.down")
        }
        // VoiceOver legge anche l'ordine attuale: "Ordina, Nome, Z → A".
        .accessibilityValue(
            Text("\(Text(ordine.criterio.nomeLocalizzato)), \(Text(ordine.crescente ? ordine.criterio.nomeCrescente : ordine.criterio.nomeDecrescente))")
        )
    }
}
