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
    @State private var vehicleSpecification: VehicleSpecification?
    @State private var specificationMessage: String?
    
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
            
            if vehicle.vehicleSpecificationId != nil {
                Section("Catalogue specification") {
                    if let vehicleSpecification {
                        LabeledContent(
                            "Specification",
                            value: vehicleSpecification.displayName
                        )

                        if let generation = vehicleSpecification.generation {
                            LabeledContent(
                                "Generation",
                                value: generation
                            )
                        }

                        if let engine = vehicleSpecification.engine {
                            LabeledContent(
                                "Engine",
                                value: engine
                            )
                        }

                        if let transmission = vehicleSpecification.transmission {
                            LabeledContent(
                                "Transmission",
                                value: transmission
                            )
                        }
                    } else if let specificationMessage {
                        Text(specificationMessage)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
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
        .task(id: vehicle.vehicleSpecificationId) {
            loadVehicleSpecification()
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
    
    private func loadVehicleSpecification() {
        vehicleSpecification = nil
        specificationMessage = nil

        guard let specificationId =
            vehicle.vehicleSpecificationId else {
            return
        }

        do {
            let catalogue = try CatalogueDatabase()

            vehicleSpecification =
                try catalogue.fetchVehicleSpecification(
                    id: specificationId
                )

            if vehicleSpecification == nil {
                specificationMessage =
                    "This catalogue specification is unavailable."
            }
        } catch {
            specificationMessage = error.localizedDescription
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
