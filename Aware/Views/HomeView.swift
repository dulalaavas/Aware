import SwiftUI
import SwiftData

struct HomeView: View {
    let profile: UserProfile
    @Binding var selectedTab: MainTabView.AppTab

    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moods: [MoodEntry]
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var quickText = ""
    @State private var showAddHabit = false
    @State private var habitsExpanded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    habitsCard
                    MoodCard(todayMood: todayMood)
                    quickJournalCard
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showAddHabit) {
                NavigationStack { HabitFormView() }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting), \(firstName)")
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                Text(Date.now.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
            }
            Spacer()
            Button {
                selectedTab = .profile
            } label: {
                AvatarView(profile: profile, size: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open profile")
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Still up"
        }
    }

    private var firstName: String {
        profile.name.split(separator: " ").first.map(String.init) ?? profile.name
    }

    // MARK: Habits

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Habits")
                    .font(.headline)
                    .foregroundStyle(Color.appInk)
                Spacer()
                Button {
                    showAddHabit = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add habit")
            }
            if habits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Small daily actions become who you are. Start with one habit.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appMuted)
                    Button("Add your first habit") { showAddHabit = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(visibleHabits) { habit in
                        NavigationLink {
                            HabitDetailView(habit: habit)
                        } label: {
                            HabitRow(habit: habit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if habits.count > 3 {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            habitsExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(habitsExpanded ? "Show less" : "Show all \(habits.count)")
                            Image(systemName: habitsExpanded ? "chevron.up" : "chevron.down")
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .card()
    }

    private var visibleHabits: [Habit] {
        habitsExpanded ? habits : Array(habits.prefix(3))
    }

    // MARK: Quick journal

    private var todayMood: MoodEntry? {
        moods.first { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var todayQuickNotes: [JournalEntry] {
        entries.filter { $0.isQuickNote && Calendar.current.isDateInToday($0.createdAt) }
    }

    private var quickJournalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What happened?")
                .font(.headline)
                .foregroundStyle(Color.appInk)
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Capture this moment…", text: $quickText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button(action: saveQuickNote) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(trimmedQuickText.isEmpty ? Color.appMuted.opacity(0.4) : Color.appAccent)
                }
                .buttonStyle(.plain)
                .disabled(trimmedQuickText.isEmpty)
                .accessibilityLabel("Save quick note")
            }
            if !todayQuickNotes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(todayQuickNotes.prefix(3)) { note in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(note.createdAt, format: .dateTime.hour().minute())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.appMuted)
                            Text(note.text)
                                .font(.subheadline)
                                .foregroundStyle(Color.appInk)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .card()
    }

    private var trimmedQuickText: String {
        quickText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveQuickNote() {
        let text = trimmedQuickText
        guard !text.isEmpty else { return }
        withAnimation(.spring(duration: 0.3)) {
            context.insert(JournalEntry(title: "", text: text, isQuickNote: true))
            quickText = ""
        }
    }
}

// MARK: - Habit row (shared with Habits tab)

struct HabitRow: View {
    let habit: Habit
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 12) {
            Text(habit.emoji)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(Color.appAccentSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.appInk)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Color.appFlame)
                    Text("\(habit.currentStreak) day streak")
                        .font(.caption)
                        .foregroundStyle(Color.appMuted)
                }
            }
            Spacer()
            Button(action: toggleToday) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30))
                    .foregroundStyle(habit.isCompletedToday ? Color.appAccent : Color.appMuted.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(habit.isCompletedToday ? "Mark \(habit.name) as not done today" : "Mark \(habit.name) as done today")
        }
    }

    private func toggleToday() {
        withAnimation(.spring(duration: 0.3)) {
            if let done = habit.completions.first(where: { Calendar.current.isDateInToday($0.date) }) {
                context.delete(done)
            } else {
                context.insert(HabitCompletion(date: .now, habit: habit))
            }
        }
    }
}

// MARK: - Mood card

struct MoodCard: View {
    @Environment(\.modelContext) private var context
    let todayMood: MoodEntry?

    @State private var selected: Mood?
    @State private var reason = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How are you feeling?")
                .font(.headline)
                .foregroundStyle(Color.appInk)

            HStack(spacing: 0) {
                ForEach(Mood.allCases) { mood in
                    moodButton(mood)
                }
            }

            if selected != nil {
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Why do you feel that way?", text: $reason, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Button(action: save) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.appAccent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Save mood")
                }
            } else if let todayMood {
                Text(loggedSummary(todayMood))
                    .font(.subheadline)
                    .foregroundStyle(Color.appMuted)
            }
        }
        .card()
    }

    private func moodButton(_ mood: Mood) -> some View {
        let isActive = (selected ?? todayMood?.mood) == mood
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selected = mood
                if todayMood?.mood == mood {
                    reason = todayMood?.reason ?? ""
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 30))
                    .scaleEffect(isActive ? 1.15 : 1)
                Text(mood.label)
                    .font(.caption2)
                    .foregroundStyle(isActive ? Color.appAccent : Color.appMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 4)
            .background(
                isActive ? Color.appAccentSoft : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Feeling \(mood.label)")
    }

    private func loggedSummary(_ entry: MoodEntry) -> String {
        var summary = "Logged \(entry.mood.label.lowercased()) at \(entry.createdAt.formatted(date: .omitted, time: .shortened))"
        if !entry.reason.isEmpty {
            summary += " — \(entry.reason)"
        }
        return summary
    }

    private func save() {
        guard let mood = selected else { return }
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(duration: 0.3)) {
            if let todayMood {
                todayMood.mood = mood
                todayMood.reason = trimmedReason
                todayMood.createdAt = .now
            } else {
                context.insert(MoodEntry(mood: mood, reason: trimmedReason))
            }
            selected = nil
            reason = ""
        }
    }
}
