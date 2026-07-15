import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Timeline

struct HabitSnapshot: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let streak: Int
    let doneToday: Bool
}

struct HabitsEntry: TimelineEntry {
    let date: Date
    let habits: [HabitSnapshot]
}

struct HabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsEntry {
        HabitsEntry(date: .now, habits: [
            HabitSnapshot(id: UUID(), name: "Read 20 minutes", emoji: "📖", streak: 5, doneToday: false),
            HabitSnapshot(id: UUID(), name: "Morning walk", emoji: "🚶", streak: 12, doneToday: true)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitsEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsEntry>) -> Void) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        let midnight = Calendar.current.startOfDay(for: tomorrow)
        completion(Timeline(entries: [loadEntry()], policy: .after(midnight)))
    }

    private func loadEntry() -> HabitsEntry {
        let snapshots: [HabitSnapshot]
        do {
            let context = ModelContext(SharedStore.container)
            let habits = try context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdAt)]))
            snapshots = habits.map {
                HabitSnapshot(
                    id: $0.uuid,
                    name: $0.name,
                    emoji: $0.emoji,
                    streak: $0.currentStreak,
                    doneToday: $0.isCompletedToday
                )
            }
        } catch {
            snapshots = []
        }
        return HabitsEntry(date: .now, habits: snapshots)
    }
}

// MARK: - Check-off intent (interactive widget)

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Mark a habit done or not done for today.")

    @Parameter(title: "Habit ID")
    var habitID: String

    init() {}

    init(habitID: UUID) {
        self.habitID = habitID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else { return .result() }
        let context = ModelContext(SharedStore.container)
        let descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.uuid == uuid })
        if let habit = try context.fetch(descriptor).first {
            if let done = habit.completions.first(where: { Calendar.current.isDateInToday($0.date) }) {
                context.delete(done)
            } else {
                context.insert(HabitCompletion(date: .now, habit: habit))
            }
            try context.save()
        }
        return .result()
    }
}

// MARK: - Widget

struct HabitStreaksWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HabitStreaksWidget", provider: HabitsProvider()) { entry in
            HabitStreaksWidgetView(entry: entry)
        }
        .configurationDisplayName("Habit streaks")
        .description("Your habits, their streaks, and a tap to mark them done.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HabitStreaksWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitsEntry

    var body: some View {
        Group {
            if entry.habits.isEmpty {
                emptyView
            } else if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        .containerBackground(for: .widget) {
            Color.appCard
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf")
                .font(.title3)
                .foregroundStyle(Color.appAccent)
            Text("Add a habit in Aware")
                .font(.caption)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var topHabit: HabitSnapshot? {
        entry.habits.max { $0.streak < $1.streak }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let habit = topHabit {
                HStack {
                    Text(habit.emoji)
                        .font(.title3)
                    Spacer()
                    Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                        Image(systemName: habit.doneToday ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(habit.doneToday ? Color.appAccent : Color.appMuted.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(habit.streak)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appInk)
                    Image(systemName: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(Color.appFlame)
                }
                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(Color.appMuted)
                Text(habit.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appInk)
                    .lineLimit(1)
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(entry.habits.prefix(3)) { habit in
                HStack(spacing: 10) {
                    Text(habit.emoji)
                        .font(.body)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(habit.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appInk)
                            .lineLimit(1)
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.appFlame)
                            Text("\(habit.streak) day streak")
                                .font(.caption2)
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                    Spacer()
                    Button(intent: ToggleHabitIntent(habitID: habit.id)) {
                        Image(systemName: habit.doneToday ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(habit.doneToday ? Color.appAccent : Color.appMuted.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
