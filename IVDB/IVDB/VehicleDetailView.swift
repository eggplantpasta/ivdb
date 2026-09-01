//
//  VehicleDetailView.swift
//  IVDB
//
//  Created by Brett Roper on 30/8/2026.
//

import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    @State private var isShowingEditVehicle = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingDeleteError = false
    @State private var deleteErrorMessage = ""
    
    @Environment(\.modelContext) private var modelContext
    
    let vehicle: Vehicle
    @Binding var selection: Vehicle?

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingEditVehicle = true
                } label: {
                    Image(systemName: "pencil")
                        .accessibilityLabel("Edit Vehicle")
                }
                .help("Edit Vehicle")
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .accessibilityLabel("Delete Vehicle")
                }
                .help("Delete Vehicle")
            }
        }
        .sheet(isPresented: $isShowingEditVehicle) {
            VehicleFormView(vehicle: vehicle)
        }
        .alert(
            "Delete Vehicle?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                deleteVehicle()
            }
        } message: {
            Text(
                "This will permanently delete \(vehicle.name)."
            )
        }
        .alert(
            "Could Not Delete Vehicle",
            isPresented: $isShowingDeleteError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    private func deleteVehicle() {
        modelContext.delete(vehicle)

        do {
            try modelContext.save()
            selection = nil
        } catch {
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
            isShowingDeleteError = true
        }
    }
}

#Preview {
    let vehicle = Vehicle(
        name: "My CR-V",
        registration: "1ABC234",
        colour: "Silver",
        buildYear: 2012
    )

    VehicleDetailView(
        vehicle: vehicle,
        selection: .constant(vehicle)
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}
