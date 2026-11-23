//
//  ImmaginiView.swift
//  Dispensa
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension Image {
    /// Un'immagine salvata (JPEG, PNG…); `nil` se i dati non si leggono.
    init?(dati: Data) {
#if os(iOS)
        guard let immagine = UIImage(data: dati) else { return nil }
        self.init(uiImage: immagine)
#else
        guard let immagine = NSImage(data: dati) else { return nil }
        self.init(nsImage: immagine)
#endif
    }
}

/// Miniatura quadrata con gli angoli arrotondati, al posto dell'emoji o del simbolo nelle righe.
struct MiniaturaView: View {
    let dati: Data
    var lato: CGFloat = 28

    var body: some View {
        if let immagine = Image(dati: dati) {
            immagine
                .resizable()
                .scaledToFill()
                .frame(width: lato, height: lato)
                .clipShape(RoundedRectangle(cornerRadius: lato / 5))
                .accessibilityHidden(true)
        }
    }
}

/// Sezione "Immagine" dei moduli di prodotto e struttura: scegli dalla libreria Foto, scatta (iPhone e iPad),
/// scegli un file (Mac) o togli l'immagine. La foto viene ridotta subito, prima del salvataggio.
struct SezioneImmagine: View {
    @Binding var immagine: ImmagineElaborata?

    @State private var elementoFoto: PhotosPickerItem?
    @State private var mostraFotocamera = false
    @State private var mostraFile = false
    @State private var inElaborazione = false
    @State private var errore: String?

    var body: some View {
        Section {
            if inElaborazione {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let immagine, let anteprima = Image(dati: immagine.immagine) {
                anteprima
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel(Text("Immagine scelta"))
            }
            // I fogli e gli altri modificatori stanno sul singolo pulsante, non sulla sezione:
            // in un Form i modificatori di una Section vengono copiati su ogni riga, e la fotocamera
            // aperta da più righe insieme si richiudeva subito.
            PhotosPicker(selection: $elementoFoto, matching: .images) {
                Label(immagine == nil ? "Scegli foto" : "Cambia foto", systemImage: "photo.on.rectangle")
            }
            .onChange(of: elementoFoto) {
                guard let elementoFoto else { return }
                self.elementoFoto = nil
                Task {
                    let dati = try? await elementoFoto.loadTransferable(type: Data.self)
                    await usa(dati)
                }
            }
#if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Scatta foto", systemImage: "camera") { mostraFotocamera = true }
                    .fullScreenCover(isPresented: $mostraFotocamera) {
                        FotocameraView { dati in
                            Task { await usa(dati) }
                        }
                        .ignoresSafeArea()
                    }
            }
#else
            Button("Scegli file…", systemImage: "folder") { mostraFile = true }
                .fileImporter(isPresented: $mostraFile, allowedContentTypes: [.image]) { risultato in
                    guard case .success(let indirizzo) = risultato else { return }
                    let accesso = indirizzo.startAccessingSecurityScopedResource()
                    let dati = try? Data(contentsOf: indirizzo)
                    if accesso { indirizzo.stopAccessingSecurityScopedResource() }
                    Task { await usa(dati) }
                }
#endif
            if immagine != nil {
                Button("Togli immagine", systemImage: "trash", role: .destructive) { immagine = nil }
            }
        } header: {
            Text("Immagine")
        } footer: {
            if let errore {
                Text(errore)
                    .foregroundStyle(.red)
            }
        }
    }

    private func usa(_ dati: Data?) async {
        guard let dati else {
            errore = String(localized: "Non è stato possibile leggere l'immagine.")
            return
        }
        inElaborazione = true
        let elaborata = await ElaborazioneImmagini.elaboraInBackground(dati)
        inElaborazione = false
        if let elaborata {
            immagine = elaborata
            errore = nil
        } else {
            errore = String(localized: "Questo file non è un'immagine che l'app sa leggere.")
        }
    }
}

#if os(iOS)
/// La fotocamera di sistema, per scattare una foto. Restituisce la foto in JPEG (`nil` se annullata).
struct FotocameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let scattata: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinatore {
        Coordinatore(self)
    }

    final class Coordinatore: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let fotocamera: FotocameraView

        init(_ fotocamera: FotocameraView) {
            self.fotocamera = fotocamera
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let foto = info[.originalImage] as? UIImage
            fotocamera.dismiss()
            if let dati = foto?.jpegData(compressionQuality: 0.9) {
                fotocamera.scattata(dati)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            fotocamera.dismiss()
        }
    }
}
#endif

/// L'immagine di un prodotto o di una struttura nella scheda: toccandola si apre grande.
struct ImmagineSchedaView: View {
    let dati: Data

    @State private var aperta = false

    var body: some View {
        if let immagine = Image(dati: dati) {
            Button {
                aperta = true
            } label: {
                immagine
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Immagine"))
            .accessibilityHint(Text("Apre l'immagine grande"))
#if os(iOS)
            .fullScreenCover(isPresented: $aperta) {
                VisualizzatoreImmagine(immagine: immagine)
            }
#else
            .sheet(isPresented: $aperta) {
                VisualizzatoreImmagine(immagine: immagine)
                    .frame(minWidth: 500, minHeight: 500)
            }
#endif
        }
    }
}

/// Un'immagine grande su fondo scuro, con "Fine" per chiuderla.
private struct VisualizzatoreImmagine: View {
    @Environment(\.dismiss) private var dismiss
    let immagine: Image

    var body: some View {
        NavigationStack {
            immagine
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fine") { dismiss() }
                    }
                }
        }
    }
}
