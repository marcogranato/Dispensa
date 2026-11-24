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

/// Pulsante "Scansiona codice": apre la fotocamera e restituisce il primo codice a barre o QR letto.
/// Compare solo dove lo scanner funziona (iPhone e iPad con fotocamera; non sul simulatore né sul Mac).
struct PulsanteScansione: View {
    var titolo: LocalizedStringKey = "Scansiona codice"
    let letto: (String) -> Void

    @State private var aperto = false

    var body: some View {
#if os(iOS)
        if DataScannerViewController.isSupported {
            Button(titolo, systemImage: "barcode.viewfinder") { aperto = true }
                .fullScreenCover(isPresented: $aperto) {
                    FoglioScanner { codice in
                        aperto = false
                        letto(codice)
                    }
                }
        }
#endif
    }
}

#if os(iOS)
/// Lo scanner a tutto schermo con "Annulla"; se la fotocamera non è consentita, spiega come attivarla.
private struct FoglioScanner: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    let letto: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isAvailable {
                    ScannerCodici(letto: letto)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
}

/// Lo scanner di sistema (VisionKit) in SwiftUI: legge un codice alla volta e si ferma al primo.
private struct ScannerCodici: UIViewControllerRepresentable {
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
