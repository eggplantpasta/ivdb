//
//  VehicleSpecification.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation
import SwiftData

@Model
final class VehicleSpecification {
    var id: UUID

    var make: String
    var model: String
    var generation: String?
    var yearFrom: Int?
    var yearTo: Int?
    var series: String?
    var trim: String?
    var bodyType: String?
    var engine: String?
    var transmission: String?

    init(
        id: UUID = UUID(),
        make: String,
        model: String,
        generation: String? = nil,
        yearFrom: Int? = nil,
        yearTo: Int? = nil,
        series: String? = nil,
        trim: String? = nil,
        bodyType: String? = nil,
        engine: String? = nil,
        transmission: String? = nil
    ) {
        self.id = id
        self.make = make
        self.model = model
        self.generation = generation
        self.yearFrom = yearFrom
        self.yearTo = yearTo
        self.series = series
        self.trim = trim
        self.bodyType = bodyType
        self.engine = engine
        self.transmission = transmission
    }
}
