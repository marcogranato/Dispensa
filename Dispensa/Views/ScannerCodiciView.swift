//
//  ScannerCodiciView.swift
//  Dispensa
//

import SwiftUI
#if os(iOS)
import UIKit
import Vision
import VisionKit
#endif

/// Dove si può leggere un codice con la fotocamera (iPhone e iPad con fotocamera; non sul simulatore né sul Mac).
enum ScannerCodici {
    static var disponibile: Bool {
#if os(iOS)
        DataScannerViewController.isSupported
#else
        false
#endif
    }
}

extension View {
    /// Apre lo scanner a tutto schermo quando `aperto` è vero; al primo codice letto lo chiude e chiama `letto`.
    /// Dove lo scanner non c'è non fa nulla.
    func scannerCodici(aperto: Binding<Bool>, letto: @escaping (String) -> Void) -> some View {
#if os(iOS)
        fullScreenCover(isPresented: aperto) {
            FoglioScanner { codice in
                aperto.wrappedValue = false
                letto(codice)
            }
        }
#else
        self
#endif
    }
}

/// Pulsante "Scansiona codice": apre la fotocamera e restituisce il primo codice a barre o QR letto.
/// Compare solo dove lo scanner funziona.
struct PulsanteScansione: View {
    var titolo: LocalizedStringKey = "Scansiona codice"
    let letto: (String) -> Void

    @State private var aperto = false

    var body: some View {
        if ScannerCodici.disponibile {
            Button(titolo, systemImage: "barcode.viewfinder") { aperto = true }
                .scannerCodici(aperto: $aperto, letto: letto)
        }
    }
}

/// La richiesta di aprire il modulo di un nuovo articolo, con o senza lo scanner già acceso.
/// È un valore per `.sheet(item:)`, così il modulo riceve la scelta insieme all'apertura.
struct RichiestaNuovoArticolo: Identifiable {
    let id = UUID()
    var scansiona = false
}

/// Il "+" degli articoli: dove c'è lo scanner è un menu con "Nuovo articolo" e "Scansiona codice"
/// (che apre il modulo con la fotocamera già accesa), altrimenti un semplice pulsante.
struct PulsanteNuovoArticolo: View {
    @Binding var richiesta: RichiestaNuovoArticolo?

    var body: some View {
        if ScannerCodici.disponibile {
            Menu {
                Button("Nuovo articolo", systemImage: "square.and.pencil") {
                    richiesta = RichiestaNuovoArticolo()
                }
                Button("Scansiona codice", systemImage: "barcode.viewfinder") {
                    richiesta = RichiestaNuovoArticolo(scansiona: true)
                }
            } label: {
                Label("Nuovo articolo", systemImage: "plus")
            }
        } else {
            Button("Nuovo articolo", systemImage: "plus") { richiesta = RichiestaNuovoArticolo() }
        }
    }
}

#if os(iOS)
/// Lo scanner a tutto schermo con "Annulla"; se la fotocamera non è consentita, spiega come attivarla.
private struct FoglioScanner: View {
    @Environment(\.dismiss) private var dismiss
    let letto: (String) -> Void

    var body: some View {
        NavigationStack {
            ScannerIncorporato(letto: letto)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annulla") { dismiss() }
                    }
                }
        }
    }
}
#endif

/// Lo scanner dentro un'altra schermata (es. al posto del modulo, nello stesso foglio);
/// se la fotocamera non è consentita, spiega come attivarla. Dove lo scanner non c'è resta vuoto.
struct ScannerIncorporato: View {
    let letto: (String) -> Void

#if os(iOS)
    @Environment(\.openURL) private var openURL

    var body: some View {
        if DataScannerViewController.isAvailable {
            LettoreCodici(letto: letto)
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    Text("Inquadra il codice a barre o il QR")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }
        } else {
            ContentUnavailableView {
                Label("Fotocamera non consentita", systemImage: "camera.badge.ellipsis")
            } description: {
                Text("Per leggere i codici, consenti a Dispensa di usare la fotocamera in Impostazioni.")
            } actions: {
                Button("Apri Impostazioni") {
                    if let impostazioni = URL(string: UIApplication.openSettingsURLString) {
                        openURL(impostazioni)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
#else
    var body: some View {
        EmptyView()
    }
#endif
}

#if os(iOS)

/// Lo scanner di sistema (VisionKit) in SwiftUI: legge un codice alla volta e si ferma al primo.
private struct LettoreCodici: UIViewControllerRepresentable {
    let letto: (String) -> Void

    /// I formati dei prodotti in negozio (EAN, UPC, ITF), dei codici di magazzino e dei QR.
    private static let formati: [VNBarcodeSymbology] = [
        .ean13, .ean8, .upce, .code128, .code39, .itf14, .qr, .dataMatrix,
    ]

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: Self.formati)],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinatore) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinatore {
        Coordinatore(letto: letto)
    }

    final class Coordinatore: NSObject, DataScannerViewControllerDelegate {
        private let letto: (String) -> Void
        /// Il primo codice basta: gli altri riconoscimenti che arrivano subito dopo si ignorano.
        private var giaLetto = false

        init(letto: @escaping (String) -> Void) {
            self.letto = letto
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !giaLetto else { return }
            for elemento in addedItems {
                if case .barcode(let codice) = elemento,
                   let testo = codice.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !testo.isEmpty {
                    giaLetto = true
                    dataScanner.stopScanning()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    letto(testo)
                    return
                }
            }
        }
    }
}
#endif
