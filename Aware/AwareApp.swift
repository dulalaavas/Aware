import SwiftUI
import SwiftData

@main
struct AwareApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.appAccent)
        }
        .modelContainer(for: [
            UserProfile.self,
            Habit.self,
            HabitCompletion.self,
            JournalEntry.self,
            MoodEntry.self
        ])
    }
}

/// Shows onboarding until a profile exists, then the main app.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}
