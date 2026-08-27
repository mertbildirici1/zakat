import Foundation

public enum Hawl {
    public static let lunarYearDays = 354

    public static func dueDate(from start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: lunarYearDays, to: start) ?? start
    }

    public static func daysRemaining(from start: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let due = dueDate(from: start, calendar: calendar)
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    }
}
