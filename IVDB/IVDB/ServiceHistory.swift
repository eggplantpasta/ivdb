//
//  ServiceHistory.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class ServiceHistory {
    var id: UUID

    var vehicle: Vehicle
    var serviceItem: ServiceItem

    var serviceDate: Date
    var odometerKm: Int?
    var performedBy: String?
    var cost: Double?
    var notes: String?

    init(
        id: UUID = UUID(),
        vehicle: Vehicle,
        serviceItem: ServiceItem,
        serviceDate: Date,
        odometerKm: Int? = nil,
        performedBy: String? = nil,
        cost: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicle = vehicle
        self.serviceItem = serviceItem
        self.serviceDate = serviceDate
        self.odometerKm = odometerKm
        self.performedBy = performedBy
        self.cost = cost
        self.notes = notes
    }
}
