import SwiftUI
import SwiftData

// MARK: - Habit detail

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var confirmDelete = false
    @State private var reminderOn = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Text(habit.emoji)
                        .font(.system(size: 40))
                        .frame(width: 72, height: 72)
                        .background(Color.appAccentSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Color.appInk)
                        Text("Since \(habit.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(Color.appMuted)
                    }
                }

                HStack(spacing: 12) {
                    statTile(value: habit.currentStreak, label: "Current streak", icon: "flame.fill", tint: .appFlame)
                    statTile(value: habit.bestStreak, label: "Best streak", icon: "trophy.fill", tint: .appAccent)
                    statTile(value: habit.completions.count, label: "Total days", icon: "calendar", tint: .appAccent)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 30 days")
                        .font(.headline)
                        .foregroundStyle(Color.appInk)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 10), spacing: 8) {
                        ForEach(last30Days, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(habit.isCompleted(on: day) ? Color.appAccent : Color.appMuted.opacity(0.15))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $reminderOn) {
                        Label("Daily reminder", systemImage: "bell")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.appInk)
                    }
                    if reminderOn {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .font(.subheadline)
                            .foregroundStyle(Color.appMuted)
                    }
                }
                .card()

                Button(action: toggleToday) {
                    Label(
                        habit.isCompletedToday ? "Done today" : "Mark done for today",
                        systemImage: habit.isCompletedToday ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete habit")
            }
        }
        .confirmationDialog(
            "Delete \"\(habit.name)\"? Its whole history goes with it.",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete habit", role: .destructive) {
                NotificationManager.cancelReminder(for: habit)
                context.delete(habit)
                dismiss()
            }
        }
        .onAppear {
            reminderOn = habit.reminderTime != nil
            reminderTime = habit.reminderTime ?? reminderTime
        }
        .onChange(of: reminderOn) { _, on in
            applyReminder(enabled: on)
        }
        .onChange(of: reminderTime) { _, _ in
            if reminderOn { applyReminder(enabled: true) }
        }
    }

    private func applyReminder(enabled: Bool) {
        if enabled {
            habit.reminderTime = reminderTime
            Task {
                if await NotificationManager.requestAuthorization() {
                    NotificationManager.scheduleReminder(for: habit)
                }
            }
        } else {
            habit.reminderTime = nil
            NotificationManager.cancelReminder(for: habit)
        }
    }

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<30).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private func statTile(value: Int, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.appInk)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.appMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
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

// MARK: - Habit form

struct HabitFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "✨"
    @State private var startDate = Date()
    @State private var reminderOn = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now

    private let emojiOptions = ["✨", "🏃", "📖", "🧘", "💧", "🥗", "✍️", "😴", "🎸", "🧠", "☀️", "🚶"]

    var body: some View {
        Form {
            Section("Habit") {
                TextField("Name (e.g. Read 20 minutes)", text: $name)
                DatePicker("Start date", selection: $startDate, displayedComponents: .date)
            }
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(emojiOptions, id: \.self) { option in
                        Button {
                            emoji = option
                        } label: {
                            Text(option)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    emoji == option ? Color.appAccentSoft : Color.clear,
                                    in: Circle()
                                )
                                .overlay(
                                    Circle().strokeBorder(
                                        emoji == option ? Color.appAccent : Color.clear,
                                        lineWidth: 1.5
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Icon \(option)")
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                Toggle("Daily reminder", isOn: $reminderOn)
                if reminderOn {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Reminder")
            } footer: {
                Text("A gentle nudge, every day, to keep the streak alive.")
            }
        }
        .navigationTitle("New habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(trimmedName.isEmpty)
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let habit = Habit(
            name: trimmedName,
            emoji: emoji,
            startDate: startDate,
            reminderTime: reminderOn ? reminderTime : nil
        )
        context.insert(habit)
        if reminderOn {
            Task {
                if await NotificationManager.requestAuthorization() {
                    NotificationManager.scheduleReminder(for: habit)
                }
            }
        }
        dismiss()
    }
}
