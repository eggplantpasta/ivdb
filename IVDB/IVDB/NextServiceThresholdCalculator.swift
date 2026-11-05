import Foundation

struct NextServiceThresholds: Equatable {
    let nextDueOdometerKm: Int?
    let nextDueDate: Date?

    static let unknown = NextServiceThresholds(
        nextDueOdometerKm: nil,
        nextDueDate: nil
    )
}

enum NextServiceThresholdCalculator {
    static func calculate(
        intervalKm: Int?,
        intervalMonths: Int?,
        lastServiceDate: Date?,
        lastServiceOdometerKm: Int?,
        calendar: Calendar = .current
    ) -> NextServiceThresholds {
        guard let lastServiceDate else {
            return .unknown
        }

        let nextDueOdometerKm: Int?

        if let intervalKm,
           intervalKm > 0,
           let lastServiceOdometerKm {
            let result = lastServiceOdometerKm.addingReportingOverflow(
                intervalKm
            )
            nextDueOdometerKm = result.overflow ? nil : result.partialValue
        } else {
            nextDueOdometerKm = nil
        }

        let nextDueDate: Date?

        if let intervalMonths,
           intervalMonths > 0 {
            nextDueDate = calendar.date(
                byAdding: .month,
                value: intervalMonths,
                to: lastServiceDate
            )
        } else {
            nextDueDate = nil
        }

        return NextServiceThresholds(
            nextDueOdometerKm: nextDueOdometerKm,
            nextDueDate: nextDueDate
        )
    }
}
