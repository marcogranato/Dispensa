//
//  PilaDiNavigazione.swift
//  Dispensa
//

import SwiftUI

/// `NavigationStack` di una scheda, con tutte le destinazioni dichiarate una sola volta alla base.
/// Le righe degli elenchi aprono i dettagli con `RigaNavigabile` passando una `Struttura`, un `Articolo` o un `Prodotto`.
///
/// Le destinazioni non vanno dichiarate nelle singole schermate: sul Mac, cambiando scheda o
/// chiudendo un foglio, quelle dichiarazioni possono non essere più visibili e i link smettono di funzionare.
struct PilaDiNavigazione<Contenuto: View>: View {
    @State private var percorso = NavigationPath()
    @ViewBuilder let contenuto: Contenuto

    var body: some View {
        NavigationStack(path: $percorso) {
            contenuto
                .navigationDestination(for: Struttura.self) { struttura in
                    DettaglioStrutturaView(struttura: struttura)
                }
                .navigationDestination(for: Articolo.self) { articolo in
                    DettaglioArticoloView(articolo: articolo)
                }
                .navigationDestination(for: Prodotto.self) { prodotto in
                    DettaglioProdottoView(prodotto: prodotto)
                }
        }
        .environment(\.apriNellaPila, ApriNellaPila(percorso: $percorso))
    }
}

/// Apre una schermata aggiungendola alla pila di navigazione corrente.
struct ApriNellaPila {
    fileprivate let percorso: Binding<NavigationPath>

    func callAsFunction<Valore: Hashable>(_ valore: Valore) {
        percorso.wrappedValue.append(valore)
    }
}

extension EnvironmentValues {
    @Entry var apriNellaPila: ApriNellaPila?
}

/// Riga di un elenco che apre il dettaglio di `valore`.
///
/// Su iPhone e iPad è un normale `NavigationLink`. Sul Mac un `NavigationLink` in un elenco funziona
/// tramite la selezione della riga, che a volte resta attiva dopo essere tornati indietro (per esempio
/// dopo una modifica): cliccando la riga già selezionata non succede nulla. Lì la riga è quindi un
/// pulsante che aggiunge il valore alla pila, senza passare dalla selezione.
struct RigaNavigabile<Valore: Hashable, Contenuto: View>: View {
    @Environment(\.apriNellaPila) private var apri

    let valore: Valore
    @ViewBuilder let contenuto: Contenuto

    var body: some View {
#if os(macOS)
        if let apri {
            Button {
                apri(valore)
            } label: {
                HStack {
                    contenuto
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: valore) { contenuto }
        }
#else
        NavigationLink(value: valore) { contenuto }
#endif
    }
}
