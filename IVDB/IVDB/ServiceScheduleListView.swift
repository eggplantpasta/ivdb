import SwiftUI
import SwiftData

struct ServiceScheduleListView: View {
    let vehicle: Vehicle

    @Query private var overrides: [ServiceScheduleOverride]
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
                            let scheduleOverride = override(
                                for: schedule.schedule.serviceItemId
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
                                    scheduleOverride: scheduleOverride
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
        }
        .padding(.vertical, 4)
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
