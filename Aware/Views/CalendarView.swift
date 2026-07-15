import SwiftUI
import SwiftData

/// Month calendar: pick a day and see everything logged on it —
/// mood, completed habits, and journal entries.
struct CalendarView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDay = Calendar.current.startOfDay(for: .now)

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthCard
                    dayLogs
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Calendar")
        }
    }

    // MARK: Month grid

    private var monthCard: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    shiftMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Previous month")

                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                Spacer()

                Button {
                    shiftMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .disabled(isCurrentMonthDisplayed)
                .accessibilityLabel("Next month")
            }

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 46)
                }
                ForEach(monthDays, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .card()
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)
        let isFuture = calendar.startOfDay(for: day) > calendar.startOfDay(for: .now)
        return Button {
            withAnimation(.spring(duration: 0.25)) { selectedDay = day }
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(.callout, design: .rounded, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected ? Color.appCard : (isFuture ? Color.appMuted.opacity(0.35) : Color.appInk)
                    )
                    .frame(width: 34, height: 34)
                    .background(isSelected ? Color.appAccent : Color.clear, in: Circle())
                    .overlay(
                        Circle().strokeBorder(
                            isToday && !isSelected ? Color.appAccent : Color.clear,
                            lineWidth: 1.5
                        )
                    )
                Circle()
                    .fill(hasLogs(on: day) ? Color.appFlame : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel(day.formatted(date: .long, time: .omitted))
    }

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: displayedMonth) }
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: displayedMonth)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var isCurrentMonthDisplayed: Bool {
        calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func hasLogs(on day: Date) -> Bool {
        moods.contains { calendar.isDate($0.createdAt, inSameDayAs: day) } ||
        habits.contains { $0.isCompleted(on: day) } ||
        entries.contains { calendar.isDate($0.createdAt, inSameDayAs: day) }
    }

    // MARK: Logs of the selected day

    private var moodOfDay: MoodEntry? {
        moods.first { calendar.isDate($0.createdAt, inSameDayAs: selectedDay) }
    }

    private var habitsOfDay: [Habit] {
        habits.filter { $0.isCompleted(on: selectedDay) }
    }

    private var entriesOfDay: [JournalEntry] {
        entries.filter { calendar.isDate($0.createdAt, inSameDayAs: selectedDay) }
    }

    private var dayLogs: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dayTitle)
                .font(.headline)
                .foregroundStyle(Color.appInk)

            if moodOfDay == nil && habitsOfDay.isEmpty && entriesOfDay.isEmpty {
                Text("Nothing logged on this day.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
                    .card(padding: 16)
            }

            if let mood = moodOfDay {
                HStack(spacing: 12) {
                    Text(mood.mood.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.appAccentSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Felt \(mood.mood.label.lowercased())")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.appInk)
                        if !mood.reason.isEmpty {
                            Text(mood.reason)
                                .font(.subheadline)
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .card(padding: 16)
            }

            if !habitsOfDay.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Habits done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(habitsOfDay) { habit in
                                HStack(spacing: 6) {
                                    Text(habit.emoji)
                                    Text(habit.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.appInk)
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.appAccent)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(Color.appAccentSoft, in: Capsule())
                            }
                        }
                    }
                }
                .card(padding: 16)
            }

            ForEach(entriesOfDay) { entry in
                NavigationLink {
                    JournalDetailView(entry: entry)
                } label: {
                    JournalRow(entry: entry)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dayTitle: String {
        if calendar.isDateInToday(selectedDay) { return "Today" }
        if calendar.isDateInYesterday(selectedDay) { return "Yesterday" }
        return selectedDay.formatted(date: .complete, time: .omitted)
    }
}
