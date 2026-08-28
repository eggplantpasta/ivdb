//
//  ServiceSchedule.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation

struct ServiceSchedule: Identifiable, Hashable {
    let id: UUID

    let vehicleSpecificationId: UUID
    let serviceItemId: UUID

    let intervalKm: Int?
    let intervalMonths: Int?
    let notes: String?

    init(
        id: UUID,
        vehicleSpecificationId: UUID,
        serviceItemId: UUID,
        intervalKm: Int? = nil,
        intervalMonths: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicleSpecificationId = vehicleSpecificationId
        self.serviceItemId = serviceItemId
        self.intervalKm = intervalKm
        self.intervalMonths = intervalMonths
        self.notes = notes
    }
}
