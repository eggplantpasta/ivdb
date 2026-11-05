//
//  Vehicle.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID

    var vehicleSpecificationId: UUID?

    var name: String
    var registration: String?
    var vin: String?
    var colour: String?
    var buildYear: Int?
    var currentOdometerKm: Int? = nil
    var odometerUpdatedAt: Date? = nil
    var notes: String?

    init(
        id: UUID = UUID(),
        vehicleSpecificationId: UUID? = nil,
        name: String,
        registration: String? = nil,
        vin: String? = nil,
        colour: String? = nil,
        buildYear: Int? = nil,
        currentOdometerKm: Int? = nil,
        odometerUpdatedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.vehicleSpecificationId = vehicleSpecificationId
        self.name = name
        self.registration = registration
        self.vin = vin
        self.colour = colour
        self.buildYear = buildYear
        self.currentOdometerKm = currentOdometerKm
        self.odometerUpdatedAt = odometerUpdatedAt
        self.notes = notes
    }
}
