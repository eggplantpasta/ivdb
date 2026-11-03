import SwiftUI
import SwiftData

struct ServiceHistoryListView: View {
    let vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @State private var editingRecord: ServiceHistory?
    @State private var recordToDelete: ServiceHistory?
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingDeleteError = false
    @State private var deleteErrorMessage = ""

    @Query private var history: [ServiceHistory]
    @State private var serviceItemNames: [UUID: String] = [:]
    @State private var catalogueErrorMessage: String?
    @State private var isShowingAddServiceHistory = false

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        let vehicleId = vehicle.id
        _history = Query(
            filter: #Predicate<ServiceHistory> { record in
                record.vehicle.id == vehicleId
            },
            sort: \ServiceHistory.serviceDate,
            order: .reverse
        )
    }

    private var sortedHistory: [ServiceHistory] {
        // UUID strings give equal-date records a stable order without changing the schema.
        history.sorted {
            if $0.serviceDate != $1.serviceDate {
                return $0.serviceDate > $1.serviceDate
            }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private var serviceItemIds: Set<UUID> {
        Set(history.map(\.serviceItemId))
    }

    var body: some View {
        List {
            if let error = _history.fetchError {
                ContentUnavailableView(
                    "Could Not Load Service History",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            } else if history.isEmpty {
                ContentUnavailableView(
                    "No Service History",
                    systemImage: "wrench.and.screwdriver",
                    description: Text("No maintenance has been recorded for \(vehicle.name) yet.")
                )
            } else {
                if let catalogueErrorMessage {
                    Section {
                        Text("Some service names could not be loaded. Your history is still available.")
                        Text(catalogueErrorMessage)
                            .foregroundStyle(.secondary)
                        Button("Retry Catalogue Lookup") {
                            loadServiceItemNames()
                        }
                    }
                }

                Section(vehicle.name) {
                    ForEach(sortedHistory) { record in
                        Button {
                            editingRecord = record
                        } label: {
                            ServiceHistoryRow(
                                record: record,
                                serviceItemName: serviceItemNames[record.serviceItemId]
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Edit service history")
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") {
                                editingRecord = record
                            }
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                requestDeletion(of: record)
                            }
                        }
                        #if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                requestDeletion(of: record)
                            }
                        }
                        #endif
                    }
                }
            }
        }
        .navigationTitle("Service History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddServiceHistory = true
                } label: {
                    Label("Add Service History", systemImage: "plus")
                }
                .help("Add Service History")
            }
        }
        .sheet(isPresented: $isShowingAddServiceHistory) {
            ServiceHistoryFormView(vehicle: vehicle, locale: locale)
        }
        .sheet(item: $editingRecord) { record in
            ServiceHistoryFormView(vehicle: vehicle, record: record, locale: locale)
        }
        .confirmationDialog(
            "Delete Service History?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible,
            presenting: recordToDelete
        ) { record in
            Button("Delete", role: .destructive) {
                deleteRecord(record)
            }
            Button("Cancel", role: .cancel) {
                recordToDelete = nil
            }
        } message: { record in
            Text("Permanently delete the service record dated \(record.serviceDate, format: .dateTime.day().month().year())? This cannot be undone.")
        }
        .alert("Could Not Delete Service History", isPresented: $isShowingDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .task(id: serviceItemIds) {
            loadServiceItemNames()
        }
    }

    private func requestDeletion(of record: ServiceHistory) {
        recordToDelete = record
        isShowingDeleteConfirmation = true
    }

    private func deleteRecord(_ record: ServiceHistory) {
        recordToDelete = nil
        modelContext.delete(record)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
            isShowingDeleteError = true
        }
    }

    private func loadServiceItemNames() {
        serviceItemNames = [:]
        catalogueErrorMessage = nil
        guard !serviceItemIds.isEmpty else {
            return
        }

        do {
            let catalogue = try CatalogueDatabase()
            for id in serviceItemIds.sorted(by: { $0.uuidString < $1.uuidString }) {
                do {
                    // UUID lookup also resolves deprecated items used by older history.
                    if let item = try catalogue.fetchServiceItem(id: id) {
                        serviceItemNames[id] = item.name
                    }
                } catch {
                    catalogueErrorMessage = error.localizedDescription
                }
            }
        } catch {
            catalogueErrorMessage = error.localizedDescription
        }
    }
}

private struct ServiceHistoryRow: View {
    let record: ServiceHistory
    let serviceItemName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let serviceItemName {
                Text(serviceItemName)
                    .font(.headline)
            } else {
                Text("Service item unavailable")
                    .font(.headline)
            }

            LabeledContent("Service date") {
                Text(record.serviceDate, format: .dateTime.day().month().year())
            }

            if let odometerKm = record.odometerKm {
                LabeledContent("Odometer") {
                    Text("\(odometerKm, format: .number) km")
                }
            }

            if let cost = record.cost {
                // History does not yet store a currency code.
                LabeledContent("Cost") {
                    Text(cost, format: .number.precision(.fractionLength(2)))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
