import SwiftUI
import SwiftData

struct ServiceHistoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    let vehicle: Vehicle

    @State private var serviceItems: [ServiceItem] = []
    @State private var selectedServiceItemId: UUID?
    @State private var serviceDate = Date()
    @State private var odometerKm = ""
    @State private var performedBy = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var catalogueErrorMessage: String?
    @State private var isShowingSaveError = false
    @State private var saveErrorMessage = ""

    private var parsedOdometer: Int? {
        guard let text = optionalText(odometerKm),
              text.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(text) else {
            return nil
        }
        return value
    }

    private var parsedCost: Double? {
        guard let text = optionalText(cost) else {
            return nil
        }
        // Validate the whole input before parsing; do not accept partial numbers,
        // grouping separators, scientific notation or non-finite values.
        let normalized = text.replacingOccurrences(
            of: locale.decimalSeparator ?? ".", with: "."
        )
        guard normalized.allSatisfy({ ($0.isASCII && $0.isNumber) || $0 == "." }),
              normalized.filter({ $0 == "." }).count <= 1,
              let value = Double(normalized), value.isFinite, value >= 0 else {
            return nil
        }
        return value
    }

    private var isOdometerValid: Bool {
        optionalText(odometerKm) == nil || parsedOdometer != nil
    }

    private var isCostValid: Bool {
        optionalText(cost) == nil || parsedCost != nil
    }

    private var canSave: Bool {
        serviceItems.contains { $0.id == selectedServiceItemId }
            && isOdometerValid && isCostValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    LabeledContent("Vehicle", value: vehicle.name)
                    Picker("Service item", selection: $selectedServiceItemId) {
                        Text("Select a service item").tag(nil as UUID?)
                        ForEach(serviceItems) { item in
                            Text(item.name).tag(Optional(item.id))
                        }
                    }

                    if let catalogueErrorMessage {
                        Text(catalogueErrorMessage)
                            .foregroundStyle(.red)
                        Button("Retry Catalogue Loading") {
                            loadServiceItems()
                        }
                    } else if selectedServiceItemId == nil {
                        Text("Select the maintenance action performed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    DatePicker("Service date", selection: $serviceDate, displayedComponents: .date)
                }

                Section("Details (optional)") {
                    TextField("Odometer (km)", text: $odometerKm)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    if !isOdometerValid {
                        Text("Enter a whole number of kilometres, zero or greater, without separators.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TextField("Performed by", text: $performedBy)
                    TextField("Cost", text: $cost)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    if !isCostValid {
                        Text("Enter an amount of zero or greater, using \(locale.decimalSeparator ?? ".") as the decimal separator and no grouping separators.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Service History")
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
                loadServiceItems()
            }
            .alert("Could Not Save Service History", isPresented: $isShowingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private func loadServiceItems() {
        catalogueErrorMessage = nil
        do {
            let catalogue = try CatalogueDatabase()
            serviceItems = try catalogue.fetchServiceItems()
            if serviceItems.isEmpty {
                catalogueErrorMessage = "No service items are available in the catalogue. A service item is required to save history."
            }
        } catch {
            serviceItems = []
            catalogueErrorMessage = error.localizedDescription
        }
    }

    private func save() {
        guard canSave, let selectedServiceItemId else {
            return
        }

        let record = ServiceHistory(
            vehicle: vehicle,
            serviceItemId: selectedServiceItemId,
            serviceDate: serviceDate,
            odometerKm: parsedOdometer,
            performedBy: optionalText(performedBy),
            cost: parsedCost,
            notes: optionalText(notes)
        )
        modelContext.insert(record)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Remove only this failed insertion, preserving other pending changes.
            modelContext.delete(record)
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
        }
    }

    private func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
