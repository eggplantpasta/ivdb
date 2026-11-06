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

enum ServiceDueStatus: Int {
    case due
    case dueSoon
    case unknown
    case notDue
}

enum ServiceDueStatusCalculator {
    static func calculate(
        nextDueDate: Date?,
        nextDueOdometerKm: Int?,
        dateIntervalApplies: Bool,
        distanceIntervalApplies: Bool,
        currentDate: Date = Date(),
        currentOdometerKm: Int?,
        dueSoonDays: Int = 30,
        dueSoonKm: Int = 1_000,
        calendar: Calendar = .current
    ) -> ServiceDueStatus {
        var isDue = false
        var isDueSoon = false
        var hasUnknownDimension = false
        var hasEvaluableDimension = false

        if dateIntervalApplies {
            if let nextDueDate {
                hasEvaluableDimension = true

                let currentDay = calendar.startOfDay(for: currentDate)
                let dueDay = calendar.startOfDay(for: nextDueDate)

                if currentDay >= dueDay {
                    isDue = true
                } else if let dueSoonStart = calendar.date(
                    byAdding: .day,
                    value: -dueSoonDays,
                    to: dueDay
                ),
                          currentDay >= dueSoonStart {
                    isDueSoon = true
                }
            } else {
                hasUnknownDimension = true
            }
        }

        if distanceIntervalApplies {
            if let nextDueOdometerKm,
               let currentOdometerKm {
                hasEvaluableDimension = true

                if currentOdometerKm >= nextDueOdometerKm {
                    isDue = true
                } else {
                    let dueSoonStart = max(
                        0,
                        nextDueOdometerKm - dueSoonKm
                    )

                    if currentOdometerKm >= dueSoonStart {
                        isDueSoon = true
                    }
                }
            } else {
                hasUnknownDimension = true
            }
        }

        if isDue {
            return .due
        }

        if isDueSoon {
            return .dueSoon
        }

        if hasUnknownDimension || !hasEvaluableDimension {
            return .unknown
        }

        return .notDue
    }
}
