//
//  GettoneEtichettaView.swift
//  Dispensa
//

import SwiftUI

extension ColoreEtichetta {
    /// Il colore di sistema corrispondente (si adatta da solo al tema chiaro e scuro).
    var colore: Color {
        switch self {
        case .rosso: .red
        case .arancione: .orange
        case .giallo: .yellow
        case .verde: .green
        case .menta: .mint
        case .azzurro: .cyan
        case .blu: .blue
        case .viola: .purple
        case .rosa: .pink
        case .marrone: .brown
        case .grigio: .gray
        }
    }
}

/// Un'etichetta come piccolo "gettone" colorato: "#colazione".
/// Il testo resta sempre leggibile; il colore è solo un aiuto in più.
struct GettoneEtichettaView: View {
    let nome: String
    let colore: ColoreEtichetta?

    init(_ etichetta: Etichetta) {
        self.init(nome: etichetta.nomeConCancelletto, colore: etichetta.colore)
    }

    init(nome: String, colore: ColoreEtichetta?) {
        self.nome = nome
        self.colore = colore
    }

    var body: some View {
        let tinta = colore?.colore ?? Color.gray
        Text(nome)
            .font(.caption)
            .lineLimit(1)
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tinta.opacity(0.2)))
            .overlay(Capsule().strokeBorder(tinta.opacity(0.7)))
    }
}

/// Gettoni di più etichette, che vanno a capo quando non stanno su una riga.
struct GettoniEtichetteView: View {
    let etichette: [Etichetta]

    var body: some View {
        DisposizioneAFlusso {
            ForEach(etichette) { etichetta in
                GettoneEtichettaView(etichetta)
            }
        }
    }
}

/// Mette le viste una dopo l'altra, andando a capo come le parole di un testo.
struct DisposizioneAFlusso: Layout {
    var spaziatura: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        disponi(subviews, larghezzaMassima: proposal.width ?? .infinity).dimensione
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let posizioni = disponi(subviews, larghezzaMassima: bounds.width).posizioni
        for (vista, punto) in zip(subviews, posizioni) {
            vista.place(at: CGPoint(x: bounds.minX + punto.x, y: bounds.minY + punto.y), proposal: .unspecified)
        }
    }

    private func disponi(_ subviews: Subviews, larghezzaMassima: CGFloat) -> (posizioni: [CGPoint], dimensione: CGSize) {
        var posizioni: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var altezzaRiga: CGFloat = 0
        var larghezza: CGFloat = 0
        for vista in subviews {
            let misura = vista.sizeThatFits(.unspecified)
            if x > 0, x + misura.width > larghezzaMassima {
                x = 0
                y += altezzaRiga + spaziatura
                altezzaRiga = 0
            }
            posizioni.append(CGPoint(x: x, y: y))
            x += misura.width + spaziatura
            altezzaRiga = max(altezzaRiga, misura.height)
            larghezza = max(larghezza, x - spaziatura)
        }
        return (posizioni, CGSize(width: larghezza, height: y + altezzaRiga))
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(ColoreEtichetta.allCases) { colore in
            GettoneEtichettaView(nome: "#\(colore.rawValue)", colore: colore)
        }
        GettoneEtichettaView(nome: "#senzacolore", colore: nil)
    }
    .padding()
}
