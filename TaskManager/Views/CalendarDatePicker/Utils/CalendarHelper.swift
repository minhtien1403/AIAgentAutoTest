import Foundation

/// Builds a Monday-first 6×7 grid with previous/next month overflow.
final class CalendarHelper {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Monday = 0 … Sunday = 6 (relative to `Calendar`’s `weekday` values).
    private func mondayBasedOffset(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        // Apple: 1 = Sunday … 7 = Saturday
        return (weekday + 5) % 7
    }

    func generateDays(monthContaining date: Date) -> [CalendarDay] {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let startComponents = DateComponents(year: y, month: m, day: 1)
        guard let firstOfMonth = calendar.date(from: startComponents) else { return [] }

        let leading = mondayBasedOffset(for: firstOfMonth)
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: firstOfMonth) else { return [] }

        var result: [CalendarDay] = []
        result.reserveCapacity(42)

        for i in 0 ..< 42 {
            guard let dayDate = calendar.date(byAdding: .day, value: i, to: gridStart) else { continue }
            let dayNum = calendar.component(.day, from: dayDate)
            let inMonth = calendar.component(.year, from: dayDate) == y && calendar.component(.month, from: dayDate) == m
            let today = calendar.isDateInToday(dayDate)
            result.append(CalendarDay(date: dayDate, number: dayNum, isCurrentMonth: inMonth, isToday: today))
        }
        return result
    }

    func nextMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: startOfMonth(for: date)) ?? date
    }

    func previousMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: startOfMonth(for: date)) ?? date
    }

    func nextYear(from date: Date) -> Date {
        calendar.date(byAdding: .year, value: 1, to: startOfMonth(for: date)) ?? date
    }

    func previousYear(from date: Date) -> Date {
        calendar.date(byAdding: .year, value: -1, to: startOfMonth(for: date)) ?? date
    }

    func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: startOfMonth(for: date))
    }

    private func startOfMonth(for date: Date) -> Date {
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        return calendar.date(from: DateComponents(year: y, month: m, day: 1)) ?? date
    }

    func normalizeToNoon(_ date: Date) -> Date {
        var c = calendar.dateComponents([.year, .month, .day], from: date)
        c.hour = 12
        c.minute = 0
        c.second = 0
        return calendar.date(from: c) ?? date
    }

    func isDate(_ a: Date, inSameDayAs b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }
}
