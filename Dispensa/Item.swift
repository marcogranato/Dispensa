//
//  Item.swift
//  Dispensa
//
//  Created by Marco Granato on 07/11/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
