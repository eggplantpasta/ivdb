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
    var serviceItem: ServiceItem

    var intervalKm: Int?
    var intervalMonths: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        vehicle: Vehicle,
        serviceItem: ServiceItem,
        intervalKm: Int? = nil,
        intervalMonths: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicle = vehicle
        self.serviceItem = serviceItem
        self.intervalKm = intervalKm
        self.intervalMonths = intervalMonths
        self.notes = notes
    }
}

