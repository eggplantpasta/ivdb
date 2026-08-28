//
//  ServiceItem.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class ServiceItem {
    var id: UUID

    var name: String
    var itemDescription: String?

    init(
        id: UUID = UUID(),
        name: String,
        itemDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
    }
}
