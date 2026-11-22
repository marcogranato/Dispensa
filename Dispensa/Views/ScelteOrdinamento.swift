//
//  ScelteOrdinamento.swift
//  Dispensa
//

import SwiftUI

/// Le scelte del sottomenu "Ordina": il criterio e il verso, con la spunta su quelli attivi.
struct ScelteOrdinamento<Criterio: CriterioOrdinamento>: View {
    let criteri: [Criterio]
    @Binding var ordine: Ordine<Criterio>

    var body: some View {
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
    }
}
