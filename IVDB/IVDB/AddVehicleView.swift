//
//  AddVehicleView.swift
//  IVDB
//
//  Created by Brett Roper on 31/8/2026.
//

import SwiftUI
import SwiftData

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var registration = ""
    @State private var vin = ""
    @State private var colour = ""
    @State private var buildYear = ""
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Name", text: $name)
                    TextField("Registration", text: $registration)
                    TextField("VIN", text: $vin)
                    TextField("Colour", text: $colour)
                    TextField("Build year", text: $buildYear)
                }

                Section("Notes") {
                    TextField(
                        "Notes",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Vehicle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let vehicle = Vehicle(
            name: name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            registration: optionalText(registration),
            vin: optionalText(vin),
            colour: optionalText(colour),
            buildYear: Int(buildYear),
            notes: optionalText(notes)
        )

        modelContext.insert(vehicle)
        dismiss()
    }

    private func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    AddVehicleView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
