import SwiftUI
import SwiftData

struct ServiceHistoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale

    let vehicle: Vehicle
    private let record: ServiceHistory?

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

    init(vehicle: Vehicle, record: ServiceHistory? = nil, locale: Locale = .current) {
        self.vehicle = vehicle
        self.record = record
        _selectedServiceItemId = State(initialValue: record?.serviceItemId)
        _serviceDate = State(initialValue: record?.serviceDate ?? Date())
        _odometerKm = State(initialValue: record?.odometerKm.map(String.init) ?? "")
        _performedBy = State(initialValue: record?.performedBy ?? "")
        _cost = State(initialValue: record?.cost.map {
            $0.formatted(
                .number.grouping(.never)
                    .precision(.significantDigits(1...17))
                    .locale(locale)
            )
        } ?? "")
        _notes = State(initialValue: record?.notes ?? "")
    }

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
        let hasServiceItem = serviceItems.contains { $0.id == selectedServiceItemId }
            || (record != nil && selectedServiceItemId == record?.serviceItemId)
        return hasServiceItem && isOdometerValid && isCostValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    LabeledContent("Vehicle", value: vehicle.name)
                    Picker("Service item", selection: $selectedServiceItemId) {
                        Text("Select a service item").tag(nil as UUID?)
                        if let record, !serviceItems.contains(where: { $0.id == record.serviceItemId }) {
                            Text("Existing service item unavailable")
                                .tag(Optional(record.serviceItemId))
                        }
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
            .navigationTitle(record == nil ? "Add Service History" : "Edit Service History")
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
            // Selection lists exclude deprecated items, but existing history must
            // still resolve its original item through the UUID lookup.
            if let record, !serviceItems.contains(where: { $0.id == record.serviceItemId }) {
                if let existingItem = try catalogue.fetchServiceItem(id: record.serviceItemId) {
                    serviceItems.append(existingItem)
                } else {
                    catalogueErrorMessage = "The original service item is unavailable. You can keep it or select another item."
                }
            }
            if serviceItems.isEmpty && record == nil {
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

        let savedRecord = record ?? ServiceHistory(
            vehicle: vehicle,
            serviceItemId: selectedServiceItemId,
            serviceDate: serviceDate
        )
        let original = (
            serviceItemId: savedRecord.serviceItemId,
            serviceDate: savedRecord.serviceDate,
            odometerKm: savedRecord.odometerKm,
            performedBy: savedRecord.performedBy,
            cost: savedRecord.cost,
            notes: savedRecord.notes
        )
        savedRecord.serviceItemId = selectedServiceItemId
        savedRecord.serviceDate = serviceDate
        savedRecord.odometerKm = parsedOdometer
        savedRecord.performedBy = optionalText(performedBy)
        savedRecord.cost = parsedCost
        savedRecord.notes = optionalText(notes)
        if record == nil {
            modelContext.insert(savedRecord)
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Restore only this record so a later autosave cannot persist failed edits.
            // The draft fields remain available for retrying.
            if record == nil {
                modelContext.delete(savedRecord)
            } else {
                savedRecord.serviceItemId = original.serviceItemId
                savedRecord.serviceDate = original.serviceDate
                savedRecord.odometerKm = original.odometerKm
                savedRecord.performedBy = original.performedBy
                savedRecord.cost = original.cost
                savedRecord.notes = original.notes
            }
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
        }
    }

    private func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
