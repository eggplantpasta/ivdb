//
//  VehicleSpecification.swift
//  IVDB
//
//  Created by Brett Roper on 28/8/2026.
//

import Foundation

struct VehicleSpecification: Identifiable, Hashable {
    let id: UUID

    let make: String
    let model: String
    let generation: String?
    let yearFrom: Int?
    let yearTo: Int?
    let series: String?
    let trim: String?
    let bodyType: String?
    let engine: String?
    let transmission: String?
    let isDeprecated: Bool

    init(
        id: UUID,
        make: String,
        model: String,
        generation: String? = nil,
        yearFrom: Int? = nil,
        yearTo: Int? = nil,
        series: String? = nil,
        trim: String? = nil,
        bodyType: String? = nil,
        engine: String? = nil,
        transmission: String? = nil,
        isDeprecated: Bool = false
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
        self.isDeprecated = isDeprecated
    }
}
