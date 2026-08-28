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

    init(
        id: UUID,
        name: String,
        itemDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
    }
}
