import SwiftUI

struct ServiceScheduleListView: View {
    let vehicle: Vehicle

    @State private var loadState: LoadState = .loading

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
                            ServiceScheduleRow(
                                serviceItemName: schedule.serviceItemName,
                                intervalKm: schedule.schedule.intervalKm,
                                intervalMonths: schedule.schedule.intervalMonths,
                                notes: schedule.schedule.notes
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
    let intervalKm: Int?
    let intervalMonths: Int?
    let notes: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(serviceItemName ?? "Service item unavailable")
                .font(.headline)

            if let intervalKm, let intervalMonths {
                Text(
                    "\(intervalKm, format: .number) km or \(intervalMonths, format: .number) months"
                )
            } else if let intervalKm {
                Text("\(intervalKm, format: .number) km")
            } else if let intervalMonths {
                Text("\(intervalMonths, format: .number) months")
            }

            if let notes, !notes.isEmpty {
                Text(notes)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
