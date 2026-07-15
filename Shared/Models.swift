import Foundation
import SwiftData

// MARK: - Profile

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case other = "Other"

    var id: String { rawValue }
}

@Model
final class UserProfile {
    var name: String
    var email: String
    var birthday: Date
    var genderRaw: String
    @Attribute(.externalStorage) var photoData: Data?
    var createdAt: Date

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .other }
        set { genderRaw = newValue.rawValue }
    }

    init(name: String, email: String, birthday: Date, gender: Gender, photoData: Data? = nil) {
        self.name = name
        self.email = email
        self.birthday = birthday
        self.genderRaw = gender.rawValue
        self.photoData = photoData
        self.createdAt = .now
    }
}

// MARK: - Habits

@Model
final class Habit {
    var name: String
    var emoji: String
    var startDate: Date
    var createdAt: Date
    /// Stable identity used by widgets and notification identifiers.
    var uuid: UUID = UUID()
    /// Time of day for the daily reminder; nil means no reminder.
    var reminderTime: Date?
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, emoji: String, startDate: Date = .now, reminderTime: Date? = nil) {
        self.name = name
        self.emoji = emoji
        self.startDate = startDate
        self.createdAt = .now
        self.uuid = UUID()
        self.reminderTime = reminderTime
    }

    var completedDays: Set<Date> {
        Set(completions.map { Calendar.current.startOfDay(for: $0.date) })
    }

    func isCompleted(on date: Date) -> Bool {
        completedDays.contains(Calendar.current.startOfDay(for: date))
    }

    var isCompletedToday: Bool {
        isCompleted(on: .now)
    }

    /// Consecutive completed days ending today (or yesterday, if today isn't done yet).
    var currentStreak: Int {
        let calendar = Calendar.current
        let days = completedDays
        var day = calendar.startOfDay(for: .now)
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let days = completedDays.sorted()
        var best = 0
        var run = 0
        var previous: Date?
        for day in days {
            if let previous,
               let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}

@Model
final class HabitCompletion {
    var date: Date
    var habit: Habit?

    init(date: Date, habit: Habit? = nil) {
        self.date = date
        self.habit = habit
    }
}

// MARK: - Journal

@Model
final class JournalEntry {
    var title: String
    var text: String
    var createdAt: Date
    /// True for one-line "what happened?" captures from the home screen.
    var isQuickNote: Bool
    @Attribute(.externalStorage) var photos: [Data]
    @Attribute(.externalStorage) var audio: Data?

    init(title: String, text: String, isQuickNote: Bool = false, photos: [Data] = [], audio: Data? = nil) {
        self.title = title
        self.text = text
        self.isQuickNote = isQuickNote
        self.photos = photos
        self.audio = audio
        self.createdAt = .now
    }
}

// MARK: - Mood

enum Mood: String, Codable, CaseIterable, Identifiable {
    case delighted, happy, neutral, sad, gloomy

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .delighted: return "😄"
        case .happy: return "🙂"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .gloomy: return "😢"
        }
    }

    var label: String {
        switch self {
        case .delighted: return "Delighted"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .gloomy: return "Gloomy"
        }
    }

    /// Numeric value for charting: gloomy = 1 … delighted = 5.
    var score: Int {
        switch self {
        case .gloomy: return 1
        case .sad: return 2
        case .neutral: return 3
        case .happy: return 4
        case .delighted: return 5
        }
    }
}

@Model
final class MoodEntry {
    var moodRaw: String
    var reason: String
    var createdAt: Date

    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }

    init(mood: Mood, reason: String) {
        self.moodRaw = mood.rawValue
        self.reason = reason
        self.createdAt = .now
    }
}
