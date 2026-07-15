import SwiftUI

struct MainTabView: View {
    let profile: UserProfile

    @EnvironmentObject private var router: AppRouter
    @State private var selection: AppTab = .home
    @State private var showCreate = false

    enum AppTab: Hashable {
        case home, calendar, create, journal, profile
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(profile: profile, selectedTab: $selection)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)

            Color.clear
                .tabItem { Label("Create", systemImage: "plus.circle.fill") }
                .tag(AppTab.create)

            JournalView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
                .tag(AppTab.journal)

            ProfileView(profile: profile)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .onChange(of: selection) { oldValue, newValue in
            // The middle tab acts as a "+" button: bounce back and open the sheet.
            if newValue == .create {
                selection = oldValue
                showCreate = true
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateSheet()
        }
        .onChange(of: router.capturePending) { _, pending in
            // Widget deep link: jump home so the quick-capture field can take focus.
            if pending {
                selection = .home
            }
        }
    }
}

/// Sheet opened from the center "+" tab: pick what to create.
struct CreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var route: Route?

    enum Route {
        case habit, journal, mood
    }

    var body: some View {
        NavigationStack {
            Group {
                switch route {
                case nil:
                    chooser
                case .habit:
                    HabitFormView()
                case .journal:
                    JournalFormView()
                case .mood:
                    MoodFormView()
                }
            }
        }
    }

    private var chooser: some View {
        ScrollView {
            VStack(spacing: 14) {
                option(
                    title: "New habit",
                    subtitle: "Something small to do every day",
                    icon: "checklist"
                ) { route = .habit }

                option(
                    title: "Journal entry",
                    subtitle: "Write about your day, add photos or a voice note",
                    icon: "square.and.pencil"
                ) { route = .journal }

                option(
                    title: "Log mood",
                    subtitle: "How are you feeling right now?",
                    icon: "face.smiling"
                ) { route = .mood }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func option(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { action() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.appAccentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appInk)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.appMuted)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appMuted)
            }
            .card()
        }
        .buttonStyle(.plain)
    }
}
