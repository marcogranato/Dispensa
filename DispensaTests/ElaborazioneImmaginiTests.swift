//
//  ElaborazioneImmaginiTests.swift
//  DispensaTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Dispensa

@MainActor
struct ElaborazioneImmaginiTests {

    /// Un'immagine PNG rossa delle dimensioni indicate, con un angolo trasparente.
    private func png(larghezza: Int, altezza: Int) throws -> Data {
        let contesto = try #require(CGContext(
            data: nil, width: larghezza, height: altezza, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        contesto.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        contesto.fill(CGRect(x: 10, y: 10, width: larghezza - 10, height: altezza - 10))
        let immagine = try #require(contesto.makeImage())
        let dati = NSMutableData()
        let destinazione = try #require(CGImageDestinationCreateWithData(dati, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destinazione, immagine, nil)
        #expect(CGImageDestinationFinalize(destinazione))
        return dati as Data
    }

    /// Larghezza, altezza e tipo di un'immagine salvata.
    private func misura(_ dati: Data) throws -> (larghezza: Int, altezza: Int, tipo: String) {
        let sorgente = try #require(CGImageSourceCreateWithData(dati as CFData, nil))
        let proprieta = try #require(CGImageSourceCopyPropertiesAtIndex(sorgente, 0, nil) as? [CFString: Any])
        return (
            try #require(proprieta[kCGImagePropertyPixelWidth] as? Int),
            try #require(proprieta[kCGImagePropertyPixelHeight] as? Int),
            try #require(CGImageSourceGetType(sorgente) as String?)
        )
    }

    @Test func unaFotoGrandeVieneRidottaInJPEG() throws {
        let elaborata = try #require(ElaborazioneImmagini.elabora(try png(larghezza: 3000, altezza: 1500)))

        let immagine = try misura(elaborata.immagine)
        #expect(immagine.larghezza == ElaborazioneImmagini.latoMassimo)
        #expect(immagine.altezza == ElaborazioneImmagini.latoMassimo / 2)
        #expect(immagine.tipo == UTType.jpeg.identifier)

        let miniatura = try misura(elaborata.miniatura)
        #expect(miniatura.larghezza == ElaborazioneImmagini.latoMiniatura)
        #expect(miniatura.altezza == ElaborazioneImmagini.latoMiniatura / 2)
    }

    @Test func unaFotoPiccolaNonVieneIngrandita() throws {
        let elaborata = try #require(ElaborazioneImmagini.elabora(try png(larghezza: 100, altezza: 80)))
        let immagine = try misura(elaborata.immagine)
        #expect(immagine.larghezza == 100)
        #expect(immagine.altezza == 80)
    }

    @Test func datiCheNonSonoUnImmagine() {
        #expect(ElaborazioneImmagini.elabora(Data("non è un'immagine".utf8)) == nil)
        #expect(ElaborazioneImmagini.elabora(Data()) == nil)
    }

    @Test func immagineGiaSalvata() {
        let dati = Data([1, 2, 3])
        #expect(ImmagineElaborata(salvata: nil, miniatura: dati) == nil)
        #expect(ImmagineElaborata(salvata: dati, miniatura: nil)?.miniatura == dati)
    }
}
