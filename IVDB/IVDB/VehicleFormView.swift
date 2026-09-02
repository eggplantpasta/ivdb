//
//  AddVehicleView.swift
//  IVDB
//
//  Created by Brett Roper on 31/8/2026.
//

import SwiftUI
import SwiftData

struct VehicleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let vehicle: Vehicle?

    @State private var name: String
    @State private var registration: String
    @State private var vin: String
    @State private var colour: String
    @State private var buildYear: String
    @State private var notes: String
    
    @State private var isShowingSaveError = false
    @State private var saveErrorMessage = ""
    
    @State private var selectedVehicleSpecificationId: UUID?
    @State private var vehicleSpecifications: [VehicleSpecification] = []
    @State private var catalogueErrorMessage: String?
    @State private var isShowingSpecificationPicker = false
    
    init(vehicle: Vehicle? = nil) {
        self.vehicle = vehicle
        
        _selectedVehicleSpecificationId = State(
            initialValue: vehicle?.vehicleSpecificationId
        )

        _name = State(initialValue: vehicle?.name ?? "")
        _registration = State(
            initialValue: vehicle?.registration ?? ""
        )
        _vin = State(initialValue: vehicle?.vin ?? "")
        _colour = State(initialValue: vehicle?.colour ?? "")
        _buildYear = State(
            initialValue: vehicle?.buildYear.map(String.init) ?? ""
        )
        _notes = State(initialValue: vehicle?.notes ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedBuildYear: Int? {
        let trimmedYear = buildYear.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedYear.isEmpty else {
            return nil
        }

        return Int(trimmedYear)
    }

    private var buildYearValidationMessage: String? {
        let trimmedYear = buildYear.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedYear.isEmpty else {
            return nil
        }

        guard let parsedBuildYear else {
            return "Enter a valid year."
        }

        let latestReasonableYear = Calendar.current.component(
            .year,
            from: Date()
        ) + 1

        guard (1886...latestReasonableYear).contains(parsedBuildYear) else {
            return "Enter a year from 1886 to \(latestReasonableYear)."
        }

        return nil
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && buildYearValidationMessage == nil
    }
    
    private var selectedVehicleSpecification:
        VehicleSpecification? {
        guard let selectedVehicleSpecificationId else {
            return nil
        }

        return vehicleSpecifications.first {
            $0.id == selectedVehicleSpecificationId
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Catalogue specification") {
                    Button {
                        if vehicleSpecifications.isEmpty {
                            loadVehicleSpecifications()
                        }

                        isShowingSpecificationPicker = true
                    } label: {
                        HStack {
                            Text("Specification")
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(
                                selectedVehicleSpecification?.displayName
                                    ?? "Not listed"
                            )
                            .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let catalogueErrorMessage {
                        Text(catalogueErrorMessage)
                            .foregroundStyle(.red)
                    }
                }
                Section("Vehicle") {
                    TextField("Name", text: $name)
                    TextField("Registration", text: $registration)
                    TextField("VIN", text: $vin)
                    TextField("Colour", text: $colour)
                    TextField("Build year", text: $buildYear)
                        .keyboardType(.numberPad)

                    if let buildYearValidationMessage {
                        Text(buildYearValidationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
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
            .navigationTitle(
                vehicle == nil ? "Add Vehicle" : "Edit Vehicle"
            )
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
            .task {
                loadVehicleSpecifications()
            }
            .alert(
                "Could Not Save Vehicle",
                isPresented: $isShowingSaveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
            .sheet(isPresented: $isShowingSpecificationPicker) {
                NavigationStack {
                    VehicleSpecificationPickerView(
                        specifications: $vehicleSpecifications,
                        selection: $selectedVehicleSpecificationId
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isShowingSpecificationPicker = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func save() {
        guard canSave else {
            return
        }

        if let vehicle {
            vehicle.vehicleSpecificationId = selectedVehicleSpecificationId
            vehicle.name = trimmedName
            vehicle.registration = optionalText(registration)
            vehicle.vin = optionalText(vin)
            vehicle.colour = optionalText(colour)
            vehicle.buildYear = parsedBuildYear
            vehicle.notes = optionalText(notes)
        } else {
            let newVehicle = Vehicle(
                vehicleSpecificationId: selectedVehicleSpecificationId,
                name: trimmedName,
                registration: optionalText(registration),
                vin: optionalText(vin),
                colour: optionalText(colour),
                buildYear: parsedBuildYear,
                notes: optionalText(notes)
            )

            modelContext.insert(newVehicle)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
        }
    }
    
    private func loadVehicleSpecifications() {
        catalogueErrorMessage = nil

        do {
            let catalogue = try CatalogueDatabase()
            vehicleSpecifications =
                try catalogue.fetchVehicleSpecifications()
        } catch {
            catalogueErrorMessage = error.localizedDescription
        }
    }
    
    private func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    VehicleFormView()
        .modelContainer(for: Vehicle.self, inMemory: true)
}
