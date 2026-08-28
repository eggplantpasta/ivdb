//
//  ServiceScheduleOverride.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class ServiceScheduleOverride {
    var id: UUID

    var vehicle: Vehicle
    var serviceItemId: UUID

    var intervalKm: Int?
    var intervalMonths: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        vehicle: Vehicle,
        serviceItemId: UUID,
        intervalKm: Int? = nil,
        intervalMonths: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicle = vehicle
        self.serviceItemId = serviceItemId
        self.intervalKm = intervalKm
        self.intervalMonths = intervalMonths
        self.notes = notes
    }
}

