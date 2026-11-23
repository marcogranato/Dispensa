//
//  ElaborazioneImmagini.swift
//  Dispensa
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Un'immagine pronta da salvare: ridotta in JPEG e la sua miniatura per le righe degli elenchi.
nonisolated struct ImmagineElaborata: Equatable, Sendable {
    let immagine: Data
    let miniatura: Data
}

extension ImmagineElaborata {
    /// L'immagine già salvata in un prodotto o in una struttura; `nil` se non c'è.
    /// Senza miniatura (dati di prova) si usa l'immagine intera.
    init?(salvata: Data?, miniatura: Data?) {
        guard let salvata else { return nil }
        self.init(immagine: salvata, miniatura: miniatura ?? salvata)
    }
}

/// Riduce le foto prima di salvarle, per non appesantire i dati (e la futura sincronizzazione).
nonisolated enum ElaborazioneImmagini {
    /// Lato più lungo dell'immagine salvata, in pixel.
    static let latoMassimo = 1200
    /// Lato più lungo della miniatura, in pixel (circa 3 volte la dimensione a schermo nelle righe).
    static let latoMiniatura = 160

    /// Immagine e miniatura in JPEG, girate nel verso giusto e su fondo bianco (il JPEG non ha trasparenza).
    /// `nil` se i dati non sono un'immagine leggibile.
    static func elabora(_ dati: Data) -> ImmagineElaborata? {
        guard let sorgente = CGImageSourceCreateWithData(dati as CFData, nil),
              let immagine = jpeg(da: sorgente, lato: latoMassimo, qualita: 0.8),
              let miniatura = jpeg(da: sorgente, lato: latoMiniatura, qualita: 0.7)
        else { return nil }
        return ImmagineElaborata(immagine: immagine, miniatura: miniatura)
    }

    /// Come `elabora(_:)`, ma lontano dal thread principale: una foto grande richiede qualche istante.
    @concurrent
    static func elaboraInBackground(_ dati: Data) async -> ImmagineElaborata? {
        elabora(dati)
    }

    private static func jpeg(da sorgente: CGImageSource, lato: Int, qualita: Double) -> Data? {
        let opzioni: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: lato,
        ]
        guard let ridotta = CGImageSourceCreateThumbnailAtIndex(sorgente, 0, opzioni as CFDictionary),
              let piatta = suFondoBianco(ridotta)
        else { return nil }

        let dati = NSMutableData()
        guard let destinazione = CGImageDestinationCreateWithData(dati, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destinazione, piatta, [kCGImageDestinationLossyCompressionQuality: qualita] as CFDictionary)
        guard CGImageDestinationFinalize(destinazione) else { return nil }
        return dati as Data
    }

    private static func suFondoBianco(_ immagine: CGImage) -> CGImage? {
        let larghezza = immagine.width
        let altezza = immagine.height
        guard let contesto = CGContext(
            data: nil,
            width: larghezza,
            height: altezza,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }
        let area = CGRect(x: 0, y: 0, width: larghezza, height: altezza)
        contesto.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        contesto.fill(area)
        contesto.draw(immagine, in: area)
        return contesto.makeImage()
    }
}
