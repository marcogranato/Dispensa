//
//  TipoEtichetta.swift
//  Dispensa
//

import Foundation

/// Un'etichetta può essere una categoria (es. "Latticini") o un hashtag libero (es. "#colazione").
enum TipoEtichetta: String, CaseIterable, Identifiable {
    case categoria
    case hashtag

    var id: Self { self }

    var nomeLocalizzato: LocalizedStringResource {
        switch self {
        case .categoria: "Categoria"
        case .hashtag: "Hashtag"
        }
    }
}
