//
//  Item.swift
//  ActionClassifier Tryout
//
//  Created by Kaushik Manian on 14/7/25.
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
