import SwiftUI
import SwiftData

struct CheckDueServicesView: View {
    let vehicle: Vehicle

    @Query private var overrides: [ServiceScheduleOverride]
    @Query private var history: [ServiceHistory]
    @State private var loadState: LoadState = .loading
    @State private var isShowingUpdateOdometer = false

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
            CurrentOdometerSection(
                currentOdometerKm: vehicle.currentOdometerKm,
                odometerUpdatedAt: vehicle.odometerUpdatedAt,
                updateAction: {
                    isShowingUpdateOdometer = true
                }
            )

            switch loadState {
            case .loading:
                ProgressView()

            case .noSpecification:
                ContentUnavailableView(
                    "Cannot Check Due Services",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(
                        "This vehicle does not have a catalogue specification."
                    )
                )

            case .missingSpecification:
                ContentUnavailableView(
                    "Cannot Check Due Services",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text(
                        "This vehicle's catalogue specification is unavailable."
                    )
                )

            case .loaded(let schedules):
                if let error = _overrides.fetchError {
                    DueServicesErrorView(
                        message: error.localizedDescription
                    )
                } else if let error = _history.fetchError {
                    DueServicesErrorView(
                        message: error.localizedDescription
                    )
                } else if schedules.isEmpty {
                    ContentUnavailableView(
                        "No Recommended Service Schedule",
                        systemImage: "calendar",
                        description: Text(
                            "The catalogue has no recommended service schedule for \(vehicle.name)."
                        )
                    )
                } else {
                    Section("Services") {
                        ForEach(
                            dueServiceItems(from: schedules)
                        ) { item in
                            DueServiceRow(item: item)
                        }
                    }
                }

            case .failed(let message):
                DueServicesErrorView(message: message)

                Button("Retry") {
                    loadSchedule()
                }
            }
        }
        .navigationTitle("Check Due Services")
        .task(id: vehicle.vehicleSpecificationId) {
            loadSchedule()
        }
        .sheet(isPresented: $isShowingUpdateOdometer) {
            VehicleOdometerFormView(vehicle: vehicle)
        }
    }

    private func dueServiceItems(
        from schedules: [RecommendedServiceSchedule]
    ) -> [DueServiceItem] {
        let currentDate = Date()

        return schedules.map { recommendedSchedule in
            let schedule = recommendedSchedule.schedule
            let scheduleOverride = overrides.first {
                $0.serviceItemId == schedule.serviceItemId
            }
            let latestHistory = history.first {
                $0.serviceItemId == schedule.serviceItemId
            }

            let intervalKm = scheduleOverride == nil
                ? schedule.intervalKm
                : scheduleOverride?.intervalKm
            let intervalMonths = scheduleOverride == nil
                ? schedule.intervalMonths
                : scheduleOverride?.intervalMonths

            let thresholds = NextServiceThresholdCalculator.calculate(
                intervalKm: intervalKm,
                intervalMonths: intervalMonths,
                lastServiceDate: latestHistory?.serviceDate,
                lastServiceOdometerKm: latestHistory?.odometerKm
            )
            let status = ServiceDueStatusCalculator.calculate(
                nextDueDate: thresholds.nextDueDate,
                nextDueOdometerKm: thresholds.nextDueOdometerKm,
                dateIntervalApplies: intervalMonths != nil,
                distanceIntervalApplies: intervalKm != nil,
                currentDate: currentDate,
                currentOdometerKm: vehicle.currentOdometerKm
            )

            return DueServiceItem(
                id: schedule.id,
                serviceItemName: recommendedSchedule.serviceItemName,
                status: status,
                nextDueDate: thresholds.nextDueDate,
                nextDueOdometerKm: thresholds.nextDueOdometerKm,
                isOverridden: scheduleOverride != nil,
                unknownReason: unknownReason(
                    status: status,
                    latestHistory: latestHistory,
                    intervalKm: intervalKm,
                    intervalMonths: intervalMonths,
                    thresholds: thresholds
                )
            )
        }
        .sorted { first, second in
            if first.status.rawValue != second.status.rawValue {
                return first.status.rawValue < second.status.rawValue
            }

            let firstName = first.serviceItemName ?? ""
            let secondName = second.serviceItemName ?? ""
            let comparison = firstName.localizedStandardCompare(
                secondName
            )

            if comparison != .orderedSame {
                return comparison == .orderedAscending
            }

            return first.id.uuidString < second.id.uuidString
        }
    }

    private func unknownReason(
        status: ServiceDueStatus,
        latestHistory: ServiceHistory?,
        intervalKm: Int?,
        intervalMonths: Int?,
        thresholds: NextServiceThresholds
    ) -> LocalizedStringResource? {
        guard status == .unknown else {
            return nil
        }

        guard let latestHistory else {
            return "No service history"
        }

        if intervalMonths != nil,
           thresholds.nextDueDate == nil {
            return "Next due date unavailable"
        }

        if intervalKm != nil,
           latestHistory.odometerKm == nil {
            return "Last service odometer unavailable"
        }

        if intervalKm != nil,
           thresholds.nextDueOdometerKm != nil,
           vehicle.currentOdometerKm == nil {
            return "Current odometer unavailable"
        }

        return "Insufficient information"
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

private extension CheckDueServicesView {
    enum LoadState {
        case loading
        case noSpecification
        case missingSpecification
        case loaded([RecommendedServiceSchedule])
        case failed(String)
    }
}

private struct CurrentOdometerSection: View {
    let currentOdometerKm: Int?
    let odometerUpdatedAt: Date?
    let updateAction: () -> Void

    var body: some View {
        Section("Current odometer") {
            if let currentOdometerKm {
                LabeledContent("Reading") {
                    Text(
                        "\(currentOdometerKm, format: .number) km"
                    )
                }

                if let odometerUpdatedAt {
                    LabeledContent("Recorded") {
                        Text(
                            odometerUpdatedAt,
                            format: .dateTime
                                .day()
                                .month()
                                .year()
                                .hour()
                                .minute()
                        )
                    }
                }
            } else {
                Text("No current odometer reading")
                    .foregroundStyle(.secondary)
            }

            Button(action: updateAction) {
                Label("Update Odometer", systemImage: "gauge")
            }
        }
    }
}

private struct DueServicesErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            "Could Not Check Due Services",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}

private struct DueServiceItem: Identifiable {
    let id: UUID
    let serviceItemName: String?
    let status: ServiceDueStatus
    let nextDueDate: Date?
    let nextDueOdometerKm: Int?
    let isOverridden: Bool
    let unknownReason: LocalizedStringResource?
}

private struct DueServiceRow: View {
    let item: DueServiceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(
                    item.serviceItemName
                        ?? "Service item unavailable"
                )
                .font(.headline)

                Spacer()

                ServiceDueStatusLabel(status: item.status)
            }

            if item.isOverridden {
                Text("Vehicle-specific override")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let nextDueDate = item.nextDueDate {
                LabeledContent("Next due date") {
                    Text(
                        nextDueDate,
                        format: .dateTime.day().month().year()
                    )
                }
            }

            if let nextDueOdometerKm =
                item.nextDueOdometerKm {
                LabeledContent("Next due odometer") {
                    Text(
                        "\(nextDueOdometerKm, format: .number) km"
                    )
                }
            }

            if item.nextDueDate == nil,
               item.nextDueOdometerKm == nil {
                LabeledContent(
                    "Next due",
                    value: "Unknown"
                )
            }

            if let unknownReason = item.unknownReason {
                Text(unknownReason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ServiceDueStatusLabel: View {
    let status: ServiceDueStatus

    var body: some View {
        Label {
            Text(status.title)
        } icon: {
            Image(systemName: status.systemImage)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(status.colour)
    }
}

private extension ServiceDueStatus {
    var title: LocalizedStringResource {
        switch self {
        case .due:
            "Due"
        case .dueSoon:
            "Due Soon"
        case .unknown:
            "Unknown"
        case .notDue:
            "Not Due"
        }
    }

    var systemImage: String {
        switch self {
        case .due:
            "exclamationmark.circle.fill"
        case .dueSoon:
            "clock.badge.exclamationmark"
        case .unknown:
            "questionmark.circle"
        case .notDue:
            "checkmark.circle"
        }
    }

    var colour: Color {
        switch self {
        case .due:
            .red
        case .dueSoon:
            .orange
        case .unknown, .notDue:
            .secondary
        }
    }
}
