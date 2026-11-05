import SwiftUI
import SwiftData

struct ServiceScheduleListView: View {
    let vehicle: Vehicle

    @Query private var overrides: [ServiceScheduleOverride]
    @Query private var history: [ServiceHistory]
    @State private var loadState: LoadState = .loading
    @State private var editingSchedule: RecommendedServiceSchedule?

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        let vehicleId = vehicle.id
        _overrides = Query(
            filter: #Predicate<ServiceScheduleOverride> { override in
                override.vehicle.id == vehicleId
            },
            sort: \ServiceScheduleOverride.id
        )
        _history = Query(
            filter: #Predicate<ServiceHistory> { record in
                record.vehicle.id == vehicleId
            },
            sort: \ServiceHistory.serviceDate,
            order: .reverse
        )
    }

    var body: some View {
        List {
            switch loadState {
            case .loading:
                ProgressView()

            case .noSpecification:
                ContentUnavailableView(
                    "No Service Schedule",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(
                        "This vehicle does not have a catalogue specification."
                    )
                )

            case .missingSpecification:
                ContentUnavailableView(
                    "Service Schedule Unavailable",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(
                        "This vehicle's catalogue specification is unavailable."
                    )
                )

            case .loaded(let schedules):
                if let error = _overrides.fetchError {
                    Section {
                        Text(
                            "Schedule overrides could not be loaded. Manufacturer recommendations are still available."
                        )
                        Text(error.localizedDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = _history.fetchError {
                    Section {
                        Text(
                            "Service history could not be loaded. Next-service thresholds are unavailable."
                        )
                        Text(error.localizedDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                if schedules.isEmpty {
                    ContentUnavailableView(
                        "No Recommended Service Schedule",
                        systemImage: "calendar",
                        description: Text(
                            "The catalogue has no recommended service schedule for \(vehicle.name)."
                        )
                    )
                } else {
                    Section(vehicle.name) {
                        ForEach(schedules) { schedule in
                            let serviceItemId =
                                schedule.schedule.serviceItemId
                            let scheduleOverride = override(
                                for: serviceItemId
                            )
                            let latestHistory = latestHistory(
                                for: serviceItemId
                            )
                            let effectiveIntervalKm =
                                scheduleOverride == nil
                                    ? schedule.schedule.intervalKm
                                    : scheduleOverride?.intervalKm
                            let effectiveIntervalMonths =
                                scheduleOverride == nil
                                    ? schedule.schedule.intervalMonths
                                    : scheduleOverride?.intervalMonths
                            let thresholds =
                                NextServiceThresholdCalculator.calculate(
                                    intervalKm: effectiveIntervalKm,
                                    intervalMonths:
                                        effectiveIntervalMonths,
                                    lastServiceDate:
                                        latestHistory?.serviceDate,
                                    lastServiceOdometerKm:
                                        latestHistory?.odometerKm
                                )

                            Button {
                                editingSchedule = schedule
                            } label: {
                                ServiceScheduleRow(
                                    serviceItemName: schedule.serviceItemName,
                                    manufacturerIntervalKm:
                                        schedule.schedule.intervalKm,
                                    manufacturerIntervalMonths:
                                        schedule.schedule.intervalMonths,
                                    manufacturerNotes:
                                        schedule.schedule.notes,
                                    scheduleOverride: scheduleOverride,
                                    isHistoryAvailable:
                                        _history.fetchError == nil,
                                    lastServiceDate:
                                        latestHistory?.serviceDate,
                                    lastServiceOdometerKm:
                                        latestHistory?.odometerKm,
                                    nextDueDate:
                                        thresholds.nextDueDate,
                                    nextDueOdometerKm:
                                        thresholds.nextDueOdometerKm,
                                    hasDistanceInterval:
                                        effectiveIntervalKm != nil,
                                    hasTimeInterval:
                                        effectiveIntervalMonths != nil
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(
                                scheduleOverride == nil
                                    ? "Add schedule override"
                                    : "Edit schedule override"
                            )
                        }
                    }
                }

            case .failed(let message):
                ContentUnavailableView(
                    "Could Not Load Service Schedule",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )

                Button("Retry") {
                    loadSchedule()
                }
            }
        }
        .navigationTitle("Service Schedule")
        .task(id: vehicle.vehicleSpecificationId) {
            loadSchedule()
        }
        .sheet(item: $editingSchedule) { schedule in
            ServiceScheduleOverrideFormView(
                vehicle: vehicle,
                recommendedSchedule: schedule,
                scheduleOverride: override(
                    for: schedule.schedule.serviceItemId
                )
            )
        }
    }

    private func override(
        for serviceItemId: UUID
    ) -> ServiceScheduleOverride? {
        overrides.first { $0.serviceItemId == serviceItemId }
    }

    private func latestHistory(
        for serviceItemId: UUID
    ) -> ServiceHistory? {
        history.first { $0.serviceItemId == serviceItemId }
    }

    private func loadSchedule() {
        loadState = .loading

        guard let specificationId = vehicle.vehicleSpecificationId else {
            loadState = .noSpecification
            return
        }

        do {
            let catalogue = try CatalogueDatabase()

            guard try catalogue.fetchVehicleSpecification(
                id: specificationId
            ) != nil else {
                loadState = .missingSpecification
                return
            }

            loadState = .loaded(
                try catalogue.fetchRecommendedServiceSchedules(
                    vehicleSpecificationId: specificationId
                )
            )
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

private extension ServiceScheduleListView {
    enum LoadState {
        case loading
        case noSpecification
        case missingSpecification
        case loaded([RecommendedServiceSchedule])
        case failed(String)
    }
}

private struct ServiceScheduleRow: View {
    let serviceItemName: String?
    let manufacturerIntervalKm: Int?
    let manufacturerIntervalMonths: Int?
    let manufacturerNotes: String?
    let scheduleOverride: ServiceScheduleOverride?
    let isHistoryAvailable: Bool
    let lastServiceDate: Date?
    let lastServiceOdometerKm: Int?
    let nextDueDate: Date?
    let nextDueOdometerKm: Int?
    let hasDistanceInterval: Bool
    let hasTimeInterval: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(serviceItemName ?? "Service item unavailable")
                    .font(.headline)

                if scheduleOverride != nil {
                    Text("Override")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let scheduleOverride {
                LabeledContent("Manufacturer") {
                    ServiceIntervalText(
                        intervalKm: manufacturerIntervalKm,
                        intervalMonths: manufacturerIntervalMonths
                    )
                }

                LabeledContent("Effective") {
                    ServiceIntervalText(
                        intervalKm: scheduleOverride.intervalKm,
                        intervalMonths: scheduleOverride.intervalMonths
                    )
                }

                if let manufacturerNotes,
                   !manufacturerNotes.isEmpty {
                    LabeledContent("Manufacturer notes") {
                        Text(manufacturerNotes)
                    }
                }

                if let notes = scheduleOverride.notes,
                   !notes.isEmpty {
                    LabeledContent("Override notes") {
                        Text(notes)
                    }
                }
            } else {
                LabeledContent("Manufacturer") {
                    ServiceIntervalText(
                        intervalKm: manufacturerIntervalKm,
                        intervalMonths: manufacturerIntervalMonths
                    )
                }

                if let manufacturerNotes,
                   !manufacturerNotes.isEmpty {
                    Text(manufacturerNotes)
                        .foregroundStyle(.secondary)
                }
            }

            ServiceThresholdDetails(
                isHistoryAvailable: isHistoryAvailable,
                lastServiceDate: lastServiceDate,
                lastServiceOdometerKm: lastServiceOdometerKm,
                nextDueDate: nextDueDate,
                nextDueOdometerKm: nextDueOdometerKm,
                hasDistanceInterval: hasDistanceInterval,
                hasTimeInterval: hasTimeInterval
            )
        }
        .padding(.vertical, 4)
    }
}

private struct ServiceThresholdDetails: View {
    let isHistoryAvailable: Bool
    let lastServiceDate: Date?
    let lastServiceOdometerKm: Int?
    let nextDueDate: Date?
    let nextDueOdometerKm: Int?
    let hasDistanceInterval: Bool
    let hasTimeInterval: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isHistoryAvailable {
                Text("Service history unavailable")
                    .foregroundStyle(.secondary)
            } else if let lastServiceDate {
                LabeledContent("Last service") {
                    Text(
                        lastServiceDate,
                        format: .dateTime.day().month().year()
                    )
                }

                if let lastServiceOdometerKm {
                    LabeledContent("Last odometer") {
                        Text(
                            "\(lastServiceOdometerKm, format: .number) km"
                        )
                    }
                } else {
                    LabeledContent("Last odometer", value: "Not recorded")
                }

                if hasTimeInterval {
                    LabeledContent("Next due date") {
                        if let nextDueDate {
                            Text(
                                nextDueDate,
                                format: .dateTime.day().month().year()
                            )
                        } else {
                            Text("Unknown")
                        }
                    }
                }

                if hasDistanceInterval {
                    LabeledContent("Next due odometer") {
                        if let nextDueOdometerKm {
                            Text(
                                "\(nextDueOdometerKm, format: .number) km"
                            )
                        } else {
                            Text("Unknown")
                        }
                    }
                }
            } else {
                Text("No service history")
                    .foregroundStyle(.secondary)
                LabeledContent("Next due", value: "Unknown")
            }
        }
    }
}

struct ServiceIntervalText: View {
    let intervalKm: Int?
    let intervalMonths: Int?

    var body: some View {
        if let intervalKm, let intervalMonths {
            Text(
                "\(intervalKm, format: .number) km or \(intervalMonths, format: .number) months"
            )
        } else if let intervalKm {
            Text("\(intervalKm, format: .number) km")
        } else if let intervalMonths {
            Text("\(intervalMonths, format: .number) months")
        } else {
            Text("No fixed interval")
        }
    }
}
