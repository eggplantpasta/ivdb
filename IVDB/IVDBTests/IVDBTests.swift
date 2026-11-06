import Foundation
import Testing
@testable import IVDB

private enum TestDates {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day
        )))
    }
}

struct NextServiceThresholdCalculatorTests {
    @Test("Distance-only interval")
    func distanceOnlyInterval() throws {
        let result = calculate(
            intervalKm: 15_000,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: 45_000
        )

        #expect(result.nextDueOdometerKm == 60_000)
        #expect(result.nextDueDate == nil)
    }

    @Test("Time-only interval")
    func timeOnlyInterval() throws {
        let result = calculate(
            intervalMonths: 12,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: 45_000
        )

        #expect(result.nextDueOdometerKm == nil)
        #expect(result.nextDueDate == (try TestDates.date(2027, 1, 15)))
    }

    @Test("Combined distance and time intervals")
    func combinedIntervals() throws {
        let result = calculate(
            intervalKm: 15_000,
            intervalMonths: 12,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: 45_000
        )

        #expect(result.nextDueOdometerKm == 60_000)
        #expect(result.nextDueDate == (try TestDates.date(2027, 1, 15)))
    }

    @Test("Missing service history")
    func missingServiceHistory() {
        let result = calculate(
            intervalKm: 15_000,
            intervalMonths: 12,
            lastServiceDate: nil,
            lastServiceOdometerKm: 45_000
        )

        #expect(result == .unknown)
    }

    @Test("Missing last-service odometer")
    func missingLastServiceOdometer() throws {
        let result = calculate(
            intervalKm: 15_000,
            intervalMonths: 12,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: nil
        )

        #expect(result.nextDueOdometerKm == nil)
        #expect(result.nextDueDate == (try TestDates.date(2027, 1, 15)))
    }

    @Test("End-of-month date arithmetic")
    func endOfMonthDateArithmetic() throws {
        let result = calculate(
            intervalMonths: 1,
            lastServiceDate: try TestDates.date(2024, 1, 31),
            lastServiceOdometerKm: nil
        )

        #expect(result.nextDueDate == (try TestDates.date(2024, 2, 29)))
    }

    @Test("Zero and invalid intervals")
    func zeroAndInvalidIntervals() throws {
        let result = calculate(
            intervalKm: 0,
            intervalMonths: -1,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: 45_000
        )

        #expect(result == .unknown)
    }

    @Test("Integer overflow protection")
    func integerOverflowProtection() throws {
        let result = calculate(
            intervalKm: 10,
            lastServiceDate: try TestDates.date(2026, 1, 15),
            lastServiceOdometerKm: Int.max - 5
        )

        #expect(result.nextDueOdometerKm == nil)
        #expect(result.nextDueDate == nil)
    }

    private func calculate(
        intervalKm: Int? = nil,
        intervalMonths: Int? = nil,
        lastServiceDate: Date?,
        lastServiceOdometerKm: Int?
    ) -> NextServiceThresholds {
        NextServiceThresholdCalculator.calculate(
            intervalKm: intervalKm,
            intervalMonths: intervalMonths,
            lastServiceDate: lastServiceDate,
            lastServiceOdometerKm: lastServiceOdometerKm,
            calendar: TestDates.calendar
        )
    }
}

struct ServiceDueStatusCalculatorTests {
    @Test("Date threshold is due when reached or passed")
    func dateThresholdReachedOrPassed() throws {
        let today = try TestDates.date(2026, 6, 15)

        #expect(status(
            nextDueDate: today,
            dateIntervalApplies: true,
            currentDate: today
        ) == .due)
        #expect(status(
            nextDueDate: try TestDates.date(2026, 6, 14),
            dateIntervalApplies: true,
            currentDate: today
        ) == .due)
    }

    @Test("Odometer threshold is due when reached or passed")
    func odometerThresholdReachedOrPassed() throws {
        let today = try TestDates.date(2026, 6, 15)

        #expect(status(
            nextDueOdometerKm: 60_000,
            distanceIntervalApplies: true,
            currentDate: today,
            currentOdometerKm: 60_000
        ) == .due)
        #expect(status(
            nextDueOdometerKm: 60_000,
            distanceIntervalApplies: true,
            currentDate: today,
            currentOdometerKm: 60_001
        ) == .due)
    }

    @Test("Due soon within 30 days")
    func dueSoonWithinThirtyDays() throws {
        let today = try TestDates.date(2026, 6, 15)
        let dueDate = try #require(
            TestDates.calendar.date(byAdding: .day, value: 30, to: today)
        )

        #expect(status(
            nextDueDate: dueDate,
            dateIntervalApplies: true,
            currentDate: today
        ) == .dueSoon)
    }

    @Test("Due soon within 1,000 kilometres")
    func dueSoonWithinOneThousandKilometres() throws {
        #expect(status(
            nextDueOdometerKm: 60_000,
            distanceIntervalApplies: true,
            currentDate: try TestDates.date(2026, 6, 15),
            currentOdometerKm: 59_000
        ) == .dueSoon)
    }

    @Test("Not due when all applicable thresholds are safely in the future")
    func safelyInFutureIsNotDue() throws {
        let today = try TestDates.date(2026, 6, 15)
        let dueDate = try #require(
            TestDates.calendar.date(byAdding: .day, value: 31, to: today)
        )

        #expect(status(
            nextDueDate: dueDate,
            nextDueOdometerKm: 60_001,
            dateIntervalApplies: true,
            distanceIntervalApplies: true,
            currentDate: today,
            currentOdometerKm: 59_000
        ) == .notDue)
    }

    @Test("Unknown when current odometer is missing")
    func missingCurrentOdometerIsUnknown() throws {
        #expect(status(
            nextDueOdometerKm: 60_000,
            distanceIntervalApplies: true,
            currentDate: try TestDates.date(2026, 6, 15),
            currentOdometerKm: nil
        ) == .unknown)
    }

    @Test("Unknown when service history is missing")
    func missingServiceHistoryIsUnknown() throws {
        #expect(status(
            dateIntervalApplies: true,
            distanceIntervalApplies: true,
            currentDate: try TestDates.date(2026, 6, 15),
            currentOdometerKm: 59_000
        ) == .unknown)
    }

    @Test("Due takes priority over due soon")
    func dueTakesPriorityOverDueSoon() throws {
        let today = try TestDates.date(2026, 6, 15)
        let dueSoonDate = try #require(
            TestDates.calendar.date(byAdding: .day, value: 15, to: today)
        )

        #expect(status(
            nextDueDate: dueSoonDate,
            nextDueOdometerKm: 60_000,
            dateIntervalApplies: true,
            distanceIntervalApplies: true,
            currentDate: today,
            currentOdometerKm: 60_000
        ) == .due)
    }

    @Test("Due soon takes priority over an unknown dimension")
    func dueSoonTakesPriorityOverUnknown() throws {
        let today = try TestDates.date(2026, 6, 15)
        let dueSoonDate = try #require(
            TestDates.calendar.date(byAdding: .day, value: 15, to: today)
        )

        #expect(status(
            nextDueDate: dueSoonDate,
            dateIntervalApplies: true,
            distanceIntervalApplies: true,
            currentDate: today,
            currentOdometerKm: nil
        ) == .dueSoon)
    }

    @Test("No fixed interval returns unknown")
    func noFixedIntervalIsUnknown() throws {
        #expect(status(
            currentDate: try TestDates.date(2026, 6, 15)
        ) == .unknown)
    }

    private func status(
        nextDueDate: Date? = nil,
        nextDueOdometerKm: Int? = nil,
        dateIntervalApplies: Bool = false,
        distanceIntervalApplies: Bool = false,
        currentDate: Date,
        currentOdometerKm: Int? = nil
    ) -> ServiceDueStatus {
        ServiceDueStatusCalculator.calculate(
            nextDueDate: nextDueDate,
            nextDueOdometerKm: nextDueOdometerKm,
            dateIntervalApplies: dateIntervalApplies,
            distanceIntervalApplies: distanceIntervalApplies,
            currentDate: currentDate,
            currentOdometerKm: currentOdometerKm,
            calendar: TestDates.calendar
        )
    }
}
