//
//  Item.swift
//  gRPC_Wallet_Demo
//
//  Created by Kanat on 10.08.2026.
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
