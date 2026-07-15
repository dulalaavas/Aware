import SwiftUI
import SwiftData

/// Full mood logging form, opened from the "+" create sheet.
/// One mood per day: logging again updates today's entry.
struct MoodFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moods: [MoodEntry]

    @State private var selected: Mood?
    @State private var reason = ""

    var body: some View {
        Form {
            Section("How are you feeling?") {
                ForEach(Mood.allCases) { mood in
                    Button {
                        selected = mood
                    } label: {
                        HStack(spacing: 12) {
                            Text(mood.emoji)
                                .font(.title2)
                            Text(mood.label)
                                .foregroundStyle(Color.appInk)
                            Spacer()
                            if selected == mood {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Section("Why do you feel that way?") {
                TextField("Optional, but it helps to know", text: $reason, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Log mood")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(selected == nil)
            }
        }
        .onAppear(perform: prefillToday)
    }

    private var todayMood: MoodEntry? {
        moods.first { Calendar.current.isDateInToday($0.createdAt) }
    }

    private func prefillToday() {
        if let todayMood, selected == nil {
            selected = todayMood.mood
            reason = todayMood.reason
        }
    }

    private func save() {
        guard let mood = selected else { return }
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if let todayMood {
            todayMood.mood = mood
            todayMood.reason = trimmedReason
            todayMood.createdAt = .now
        } else {
            context.insert(MoodEntry(mood: mood, reason: trimmedReason))
        }
        dismiss()
    }
}
