//
//  ServiceSchedule.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class ServiceSchedule {
    var id: UUID

    var vehicleSpecification: VehicleSpecification
    var serviceItem: ServiceItem

    var intervalKm: Int?
    var intervalMonths: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        vehicleSpecification: VehicleSpecification,
        serviceItem: ServiceItem,
        intervalKm: Int? = nil,
        intervalMonths: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicleSpecification = vehicleSpecification
        self.serviceItem = serviceItem
        self.intervalKm = intervalKm
        self.intervalMonths = intervalMonths
        self.notes = notes
    }
}
