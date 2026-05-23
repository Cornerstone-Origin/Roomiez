import SwiftUI

/// Horizontal calendar strip at the top of the Chore Board. Shows a few
/// recent days for context plus 4 weeks out. Each pill shows weekday +
/// day-number + a dot/count if chores are due that day. Tap to scope
/// the chore list to that date.
struct ChoreCalendarStrip: View {
    @Binding var selectedDate: Date
    var chores: [Chore]
    var pastDays:   Int = 30
    var futureDays: Int = 365

    private let cal = Calendar.current

    /// Primary orange for selected-day fill + active markers; sky blue
    /// for secondary indicators (count dots, today outline).
    private var primary:   Color { Theme.Palette.orange }
    private var secondary: Color { Theme.Palette.skyBlue }

    private var days: [Date] {
        let today = Date.now.startOfDay
        return (-pastDays...futureDays).compactMap {
            cal.date(byAdding: .day, value: $0, to: today)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.skyBlue)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.Palette.skyBlue.opacity(0.14))
                    )
                Text(monthLabel)
                    .font(.cozyHeadline)
                    .foregroundStyle(Theme.Palette.text)
                Spacer()
                Button {
                    Haptics.selection()
                    withAnimation(Theme.Motion.spring) {
                        selectedDate = .now.startOfDay
                    }
                } label: {
                    Text("Today")
                        .font(.cozy(12, weight: .bold))
                        .foregroundStyle(Theme.Palette.skyBlue)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.Palette.skyBlue.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.self) { day in
                            dayPill(day)
                                .id(day)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    // Anchor on today so the user lands on "now" but can
                    // scroll back to recent days or forward for planning.
                    proxy.scrollTo(cal.startOfDay(for: selectedDate),
                                   anchor: .center)
                }
                .onChange(of: selectedDate) { _, new in
                    withAnimation(Theme.Motion.spring) {
                        proxy.scrollTo(cal.startOfDay(for: new),
                                       anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Pill

    private func dayPill(_ date: Date) -> some View {
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday    = date.isToday
        let count      = choreCount(on: date)

        return Button {
            Haptics.selection()
            withAnimation(Theme.Motion.spring) { selectedDate = date }
        } label: {
            VStack(spacing: 5) {
                Text(weekdayLabel(date))
                    .font(.cozy(10, weight: .bold))
                    .foregroundStyle(
                        isSelected
                            ? primary
                            : (isToday ? primary : Theme.Palette.textSoft)
                    )
                Text("\(cal.component(.day, from: date))")
                    .font(.cozy(20, weight: .bold))
                    .foregroundStyle(Theme.Palette.text)
                indicatorDot(count: count, selected: isSelected)
            }
            .frame(width: 50, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        primary.opacity(0.22),
                                        primary.opacity(0.10)
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            : AnyShapeStyle(Theme.Palette.surface)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(primary.opacity(0.55))
                            : (isToday
                                ? AnyShapeStyle(primary.opacity(0.55))
                                : AnyShapeStyle(Theme.Gradients.glassBorder)),
                        lineWidth: (isSelected || isToday) ? 1.5 : 1.2
                    )
            )
        }
        // `ChoreCardPressStyle`-style press feedback: pure ButtonStyle
        // so we don't install a competing DragGesture (which would
        // block the parent horizontal ScrollView from scrolling
        // through days — see the ChoreCard fix in CLAUDE.md).
        .buttonStyle(DayPillPressStyle())
    }

    private func indicatorDot(count: Int, selected: Bool) -> some View {
        Group {
            if count > 0 {
                if selected {
                    // Filled orange circle with white number — matches
                    // the selected-day badge in the reference.
                    ZStack {
                        Circle()
                            .fill(primary)
                            .frame(width: 18, height: 18)
                        Text("\(count)")
                            .font(.cozy(10, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                } else if count == 1 {
                    Circle()
                        .fill(secondary)
                        .frame(width: 6, height: 6)
                } else {
                    Text("\(count)")
                        .font(.cozy(9, weight: .bold))
                        .foregroundStyle(secondary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(
                            Capsule().fill(secondary.opacity(0.18))
                        )
                }
            } else {
                Color.clear.frame(height: 18)
            }
        }
        .frame(height: 18)
    }

    // MARK: - Helpers

    private func choreCount(on date: Date) -> Int {
        chores.reduce(0) { acc, chore in
            guard chore.status != .done else { return acc }
            guard let due = chore.dueDate else { return acc }
            return acc + (cal.isDate(due, inSameDayAs: date) ? 1 : 0)
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: selectedDate)
    }

}

/// Press style for the calendar day pills — gives the scale-down
/// feedback without the simultaneous drag-gesture that `.pressable`
/// uses (which interferes with the parent horizontal ScrollView's
/// drag-to-scroll). Mirrors the `ChoreCardPressStyle` pattern that
/// solved the same problem for chore cards in the vertical ScrollView.
private struct DayPillPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(Theme.Motion.snappy, value: configuration.isPressed)
    }
}
