import SwiftUI
import SwiftData

struct VehicleOdometerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vehicle: Vehicle

    @State private var reading: String
    @State private var isShowingLowerReadingConfirmation = false
    @State private var isShowingSaveError = false
    @State private var saveErrorMessage = ""

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _reading = State(
            initialValue: vehicle.currentOdometerKm.map(String.init) ?? ""
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if let currentOdometerKm = vehicle.currentOdometerKm {
                    Section("Current reading") {
                        LabeledContent("Odometer") {
                            Text(
                                "\(currentOdometerKm, format: .number) km"
                            )
                        }

                        if let odometerUpdatedAt =
                            vehicle.odometerUpdatedAt {
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
                    }
                }

                Section("New reading") {
                    TextField(
                        "Odometer (km)",
                        text: $reading
                    )
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif

                    if !reading.isEmpty && parsedReading == nil {
                        Text(
                            "Enter a whole number of kilometres, zero or greater, without separators."
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Update Odometer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        requestSave()
                    }
                    .disabled(parsedReading == nil)
                }
            }
            .confirmationDialog(
                "Save Lower Odometer Reading?",
                isPresented: $isShowingLowerReadingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Save Lower Reading") {
                    save()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "The new reading is lower than the stored reading. Continue only for a correction or odometer replacement."
                )
            }
            .alert(
                "Could Not Save Odometer",
                isPresented: $isShowingSaveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
        }
    }

    private var parsedReading: Int? {
        let trimmed = reading.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty,
              trimmed.allSatisfy({
                  $0.isASCII && $0.isNumber
              }),
              let value = Int(trimmed),
              value >= 0 else {
            return nil
        }

        return value
    }

    private func requestSave() {
        guard let parsedReading else {
            return
        }

        if let currentOdometerKm = vehicle.currentOdometerKm,
           parsedReading < currentOdometerKm {
            isShowingLowerReadingConfirmation = true
        } else {
            save()
        }
    }

    private func save() {
        guard let parsedReading else {
            return
        }

        let originalOdometerKm = vehicle.currentOdometerKm
        let originalUpdatedAt = vehicle.odometerUpdatedAt

        vehicle.currentOdometerKm = parsedReading
        vehicle.odometerUpdatedAt = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            vehicle.currentOdometerKm = originalOdometerKm
            vehicle.odometerUpdatedAt = originalUpdatedAt
            saveErrorMessage = error.localizedDescription
            isShowingSaveError = true
        }
    }
}
