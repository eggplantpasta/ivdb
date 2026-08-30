//
//  ServiceItem.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation

struct ServiceItem: Identifiable, Hashable {
    let id: UUID

    let name: String
    let itemDescription: String?
    let isDeprecated: Bool

    init(
        id: UUID,
        name: String,
        itemDescription: String? = nil,
        isDeprecated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
        self.isDeprecated = isDeprecated
    }
}
