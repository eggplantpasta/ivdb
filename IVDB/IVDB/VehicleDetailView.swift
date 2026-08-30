//
//  VehicleDetailView.swift
//  IVDB
//
//  Created by Brett Roper on 30/8/2026.
//

import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    let vehicle: Vehicle

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()

                    Image(systemName: "car")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }

            Section("Vehicle") {
                LabeledContent("Name", value: vehicle.name)

                if let registration = vehicle.registration {
                    LabeledContent(
                        "Registration",
                        value: registration
                    )
                }

                if let buildYear = vehicle.buildYear {
                    LabeledContent(
                        "Build year",
                        value: String(buildYear)
                    )
                }

                if let colour = vehicle.colour {
                    LabeledContent("Colour", value: colour)
                }

                if let vin = vehicle.vin {
                    LabeledContent("VIN", value: vin)
                }
            }

            if let notes = vehicle.notes,
               !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(vehicle.name)
    }
}

#Preview {
    VehicleDetailView(
        vehicle: Vehicle(
            name: "My CR-V",
            registration: "1ABC234",
            colour: "Silver",
            buildYear: 2012
        )
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}
