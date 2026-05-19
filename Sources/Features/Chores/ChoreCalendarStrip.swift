import SwiftUI

/// Horizontal calendar strip at the top of the Chore Board. Shows a few
/// recent days for context plus 4 weeks out. Each pill shows weekday +
/// day-number + a dot/count if chores are due that day. Tap to scope
/// the chore list to that date.
struct ChoreCalendarStrip: View {
    @Binding var selectedDate: Date
    var chores: [Chore]
    var pastDays:   Int = 7
    var futureDays: Int = 90

    private let cal = Calendar.current

    private var accentGradient: LinearGradient { Theme.Gradients.accent }

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
                    .foregroundStyle(Theme.Palette.text)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Theme.Palette.divider, lineWidth: 1))
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
                        .foregroundStyle(Theme.Palette.text)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .overlay(Capsule().stroke(Theme.Palette.divider, lineWidth: 1))
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
                            ? AnyShapeStyle(Theme.Palette.text)
                            : (isToday
                                ? AnyShapeStyle(accentGradient)
                                : AnyShapeStyle(Theme.Palette.textSoft))
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
                            ? AnyShapeStyle(accentGradient)
                            : AnyShapeStyle(Theme.Palette.surface)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(Color.clear)
                            : (isToday
                                ? AnyShapeStyle(accentGradient)
                                : AnyShapeStyle(Theme.Palette.divider)),
                        lineWidth: isToday && !isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.95)
    }

    private func indicatorDot(count: Int, selected: Bool) -> some View {
        Group {
            if count > 0 {
                if count == 1 {
                    Circle()
                        .fill(accentGradient)
                        .frame(width: 5, height: 5)
                } else {
                    Text("\(count)")
                        .font(.cozy(8, weight: .bold))
                        .foregroundStyle(accentGradient)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(
                            Capsule().fill(accentGradient.opacity(0.18))
                        )
                }
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .frame(height: 10)
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
