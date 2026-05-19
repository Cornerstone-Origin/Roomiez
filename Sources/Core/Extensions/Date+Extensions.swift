import Foundation

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }

    /// "Today", "Tomorrow", "Mon", "Mar 14" — used by chore cards.
    func friendlyShort() -> String {
        if isToday    { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }
        let cal = Calendar.current
        if let days = cal.dateComponents([.day], from: .now.startOfDay, to: startOfDay).day,
           days > 0, days < 7 {
            let f = DateFormatter(); f.dateFormat = "EEEE"
            return f.string(from: self)
        }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    /// "2 min ago", "yesterday" — activity feed.
    func relative() -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: .now)
    }
}
