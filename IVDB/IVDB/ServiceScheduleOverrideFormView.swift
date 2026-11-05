import SwiftUI
import SwiftData

struct ServiceScheduleOverrideFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle
    let recommendedSchedule: RecommendedServiceSchedule
    private let scheduleOverride: ServiceScheduleOverride?

    @State private var intervalKm: String
    @State private var intervalMonths: String
    @State private var notes: String
    @State private var isShowingRemoveConfirmation = false
    @State private var isShowingPersistenceError = false
    @State private var persistenceErrorTitle = ""
    @State private var persistenceErrorMessage = ""

    init(
        vehicle: Vehicle,
        recommendedSchedule: RecommendedServiceSchedule,
        scheduleOverride: ServiceScheduleOverride?
    ) {
        self.vehicle = vehicle
        self.recommendedSchedule = recommendedSchedule
        self.scheduleOverride = scheduleOverride
        _intervalKm = State(
            initialValue: scheduleOverride?.intervalKm.map(String.init) ?? ""
        )
        _intervalMonths = State(
            initialValue:
                scheduleOverride?.intervalMonths.map(String.init) ?? ""
        )
        _notes = State(initialValue: scheduleOverride?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    LabeledContent(
                        "Vehicle",
                        value: vehicle.name
                    )
                    LabeledContent(
                        "Service item",
                        value: recommendedSchedule.serviceItemName
                            ?? "Service item unavailable"
                    )
                }

                Section("Manufacturer recommendation") {
                    LabeledContent("Interval") {
                        ServiceIntervalText(
                            intervalKm:
                                recommendedSchedule.schedule.intervalKm,
                            intervalMonths:
                                recommendedSchedule.schedule.intervalMonths
                        )
                    }

                    if let notes = recommendedSchedule.schedule.notes,
                       !notes.isEmpty {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Override") {
                    TextField(
                        "Interval kilometres",
                        text: $intervalKm
                    )
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                    if !isIntervalKmValid {
                        Text(
                            "Enter a positive whole number of kilometres without separators."
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }

                    TextField(
                        "Interval months",
                        text: $intervalMonths
                    )
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                    if !isIntervalMonthsValid {
                        Text(
                            "Enter a positive whole number of months without separators."
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }

                    if scheduleOverride == nil && !hasInterval {
                        Text("Enter at least one interval.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if scheduleOverride != nil {
                    Section {
                        Button(
                            "Remove Override",
                            role: .destructive
                        ) {
                            isShowingRemoveConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(
                scheduleOverride == nil
                    ? "Add Schedule Override"
                    : "Edit Schedule Override"
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
            .confirmationDialog(
                "Remove Schedule Override?",
                isPresented: $isShowingRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Remove Override",
                    role: .destructive
                ) {
                    removeOverride()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "The manufacturer's recommended schedule will become effective again."
                )
            }
            .alert(
                persistenceErrorTitle,
                isPresented: $isShowingPersistenceError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(persistenceErrorMessage)
            }
        }
    }

    private var parsedIntervalKm: Int? {
        positiveWholeNumber(from: intervalKm)
    }

    private var parsedIntervalMonths: Int? {
        positiveWholeNumber(from: intervalMonths)
    }

    private var isIntervalKmValid: Bool {
        optionalText(intervalKm) == nil || parsedIntervalKm != nil
    }

    private var isIntervalMonthsValid: Bool {
        optionalText(intervalMonths) == nil || parsedIntervalMonths != nil
    }

    private var hasInterval: Bool {
        parsedIntervalKm != nil || parsedIntervalMonths != nil
    }

    private var canSave: Bool {
        isIntervalKmValid
            && isIntervalMonthsValid
            && (scheduleOverride != nil || hasInterval)
    }

    private func save() {
        guard canSave else {
            return
        }

        let vehicleId = vehicle.id
        let serviceItemId = recommendedSchedule.schedule.serviceItemId
        let descriptor = FetchDescriptor<ServiceScheduleOverride>(
            predicate: #Predicate<ServiceScheduleOverride> { candidate in
                candidate.vehicle.id == vehicleId
                    && candidate.serviceItemId == serviceItemId
            }
        )

        do {
            let existingOverrides = try modelContext.fetch(descriptor)
            let editedOverrideId = scheduleOverride?.id

            guard !existingOverrides.contains(where: {
                $0.id != editedOverrideId
            }) else {
                showPersistenceError(
                    title: "Could Not Save Override",
                    message:
                        "An override already exists for this service item."
                )
                return
            }

            let savedOverride = scheduleOverride
                ?? ServiceScheduleOverride(
                    vehicle: vehicle,
                    serviceItemId: serviceItemId
                )
            let original = (
                intervalKm: savedOverride.intervalKm,
                intervalMonths: savedOverride.intervalMonths,
                notes: savedOverride.notes
            )

            savedOverride.intervalKm = parsedIntervalKm
            savedOverride.intervalMonths = parsedIntervalMonths
            savedOverride.notes = optionalText(notes)

            if scheduleOverride == nil {
                modelContext.insert(savedOverride)
            }

            do {
                try modelContext.save()
                dismiss()
            } catch {
                if scheduleOverride == nil {
                    modelContext.delete(savedOverride)
                } else {
                    savedOverride.intervalKm = original.intervalKm
                    savedOverride.intervalMonths = original.intervalMonths
                    savedOverride.notes = original.notes
                }

                showPersistenceError(
                    title: "Could Not Save Override",
                    message: error.localizedDescription
                )
            }
        } catch {
            showPersistenceError(
                title: "Could Not Save Override",
                message: error.localizedDescription
            )
        }
    }

    private func removeOverride() {
        guard let scheduleOverride else {
            return
        }

        modelContext.delete(scheduleOverride)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            showPersistenceError(
                title: "Could Not Remove Override",
                message: error.localizedDescription
            )
        }
    }

    private func positiveWholeNumber(from value: String) -> Int? {
        guard let text = optionalText(value),
              text.allSatisfy({ $0.isASCII && $0.isNumber }),
              let number = Int(text),
              number > 0 else {
            return nil
        }

        return number
    }

    private func optionalText(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? nil : trimmed
    }

    private func showPersistenceError(
        title: String,
        message: String
    ) {
        persistenceErrorTitle = title
        persistenceErrorMessage = message
        isShowingPersistenceError = true
    }
}
