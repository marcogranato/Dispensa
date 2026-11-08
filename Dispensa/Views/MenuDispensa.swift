//
//  MenuDispensa.swift
//  Dispensa
//

import SwiftUI
import SwiftData

/// Menu nel titolo con il nome della dispensa aperta (es. "Casa ▾"):
/// permette di passare a un'altra dispensa, crearne una nuova, modificarla o eliminarla.
struct MenuDispensa: View {
    let dispense: [Dispensa]
    let corrente: Dispensa
    let scegli: (Dispensa) -> Void
    let nuova: () -> Void
    let modifica: () -> Void
    let elimina: () -> Void

    var body: some View {
        Menu {
            // Il selettore in linea mostra la spunta sulla dispensa aperta.
            Picker("Dispensa", selection: Binding(
                get: { corrente.id },
                set: { id in
                    if let dispensa = dispense.first(where: { $0.id == id }) {
                        scegli(dispensa)
                    }
                }
            )) {
                ForEach(dispense) { dispensa in
                    Label(dispensa.nome, systemImage: "house")
                        .tag(dispensa.id)
                }
            }
            .pickerStyle(.inline)

            Button("Nuova dispensa…", systemImage: "plus", action: nuova)
            Button("Modifica «\(corrente.nome)»…", systemImage: "pencil", action: modifica)
            Button("Elimina «\(corrente.nome)»…", systemImage: "trash", role: .destructive, action: elimina)
        } label: {
            HStack(spacing: 4) {
                Text(corrente.nome)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
            }
        }
        // Sul Mac il sistema aggiunge una seconda freccia al menu: la nostra basta.
        .menuIndicator(.hidden)
        .accessibilityLabel(Text("Dispensa: \(corrente.nome)"))
    }
}
