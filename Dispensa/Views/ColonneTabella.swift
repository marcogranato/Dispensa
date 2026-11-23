//
//  ColonneTabella.swift
//  Dispensa
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Sceglie come mostrare un elenco: tabella su iPad in finestra larga e sul Mac, elenco su iPhone
/// e nelle finestre strette (dove una tabella mostrerebbe solo la prima colonna).
struct DisposizioneElenco<Contenuto: View>: View {
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var classe
#endif
    @ViewBuilder let contenuto: (_ tabella: Bool) -> Contenuto

    private var tabella: Bool {
#if os(iOS)
        // Anche un iPhone grande in orizzontale è "largo": lì restano le righe.
        UIDevice.current.userInterfaceIdiom == .pad && classe == .regular
#else
        true
#endif
    }

    var body: some View {
        contenuto(tabella)
    }
}

/// Una colonna di una tabella configurabile. Il `rawValue` identifica la colonna nelle impostazioni salvate.
protocol ColonnaTabella: CaseIterable, Identifiable, Hashable, RawRepresentable where RawValue == String {
    var titolo: LocalizedStringResource { get }
    /// Mostrata finché non la si nasconde.
    var visibileAllInizio: Bool { get }
    /// Sempre visibile (la colonna del nome).
    var fissa: Bool { get }
}

extension ColonnaTabella {
    var visibilitaIniziale: Visibility { visibileAllInizio ? .visible : .hidden }

    /// Vero se la colonna è mostrata con queste impostazioni.
    func visibile<Riga: Identifiable>(in colonne: TableColumnCustomization<Riga>) -> Bool {
        if fissa { return true }
        switch colonne[visibility: rawValue] {
        case .visible: return true
        case .hidden: return false
        default: return visibileAllInizio
        }
    }
}

/// Colonne mostrate, ordine e larghezze di una tabella, salvate su questo dispositivo (non nelle viste).
enum ArchivioColonne {
    static func chiave(_ tipo: TipoElenco) -> String { "colonne.\(tipo.rawValue)" }

    static func leggi<Riga: Identifiable>(_ dati: Data) -> TableColumnCustomization<Riga> {
        guard !dati.isEmpty,
              let colonne = try? JSONDecoder().decode(TableColumnCustomization<Riga>.self, from: dati)
        else { return TableColumnCustomization() }
        return colonne
    }

    static func scrivi<Riga: Identifiable>(_ colonne: TableColumnCustomization<Riga>) -> Data {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = .sortedKeys
        return (try? codificatore.encode(colonne)) ?? Data()
    }
}

/// Le impostazioni delle colonne di un elenco, lette e scritte in `UserDefaults`.
/// Tabella e menu "Colonne" usano la stessa chiave, quindi restano allineati.
@propertyWrapper
struct ColonneSalvate<Riga: Identifiable>: DynamicProperty {
    @AppStorage private var dati: Data

    init(_ tipo: TipoElenco) {
        _dati = AppStorage(wrappedValue: Data(), ArchivioColonne.chiave(tipo))
    }

    var wrappedValue: TableColumnCustomization<Riga> {
        get { ArchivioColonne.leggi(dati) }
        nonmutating set {
            // Si scrive solo se cambia davvero, per non ridisegnare la tabella a vuoto.
            guard newValue != wrappedValue else { return }
            dati = ArchivioColonne.scrivi(newValue)
        }
    }

    var projectedValue: Binding<TableColumnCustomization<Riga>> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}

/// Sottomenu "Colonne" del menu Vista: mostra o nasconde le colonne e le riporta come all'inizio.
struct MenuColonne<Riga: Identifiable, Colonna: ColonnaTabella>: View {
    @ColonneSalvate private var colonne: TableColumnCustomization<Riga>
    let disponibili: [Colonna]

    init(_ tipo: TipoElenco, righe: Riga.Type, colonne disponibili: [Colonna]) {
        _colonne = ColonneSalvate(tipo)
        self.disponibili = disponibili
    }

    var body: some View {
        Menu {
            ForEach(disponibili.filter { !$0.fissa }) { colonna in
                Toggle(isOn: Binding(
                    get: { colonna.visibile(in: colonne) },
                    set: { colonne[visibility: colonna.rawValue] = $0 ? .visible : .hidden }
                )) {
                    Text(colonna.titolo)
                }
            }
            Divider()
            Button("Ripristina colonne", systemImage: "arrow.counterclockwise") {
                colonne = TableColumnCustomization()
            }
        } label: {
            Label("Colonne", systemImage: "tablecells")
        }
    }
}
