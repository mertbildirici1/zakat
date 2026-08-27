import Foundation
@testable import ZakatEngine
import Testing

struct HawlTests {
    @Test func lunarYearIs354Days() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let due = Hawl.dueDate(from: start, calendar: calendar)
        let days = calendar.dateComponents([.day], from: start, to: due).day
        #expect(days == 354)
    }

    @Test func daysRemainingIsZeroOnDueDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let due = Hawl.dueDate(from: start, calendar: calendar)
        #expect(Hawl.daysRemaining(from: start, now: due, calendar: calendar) == 0)
    }
}
