# Aware — Be aware with yourself

An iOS app to track what you did all day: daily habits with streaks, how you're feeling (and why), and a journal of the small moments that make up your days. Built with SwiftUI + SwiftData from the handwritten design notes and user stories.

## Requirements

- **Xcode 16 or newer** (free, from the Mac App Store). This Mac currently has only Command Line Tools, so install Xcode first.
- iOS 17+ (simulator or iPhone).

## Run it

1. Install Xcode from the Mac App Store, open it once, and let it install the iOS platform when prompted.
2. Double-click `Aware.xcodeproj`.
3. Pick an iPhone simulator in the toolbar and press **⌘R**.

To run on your real iPhone: connect it, select it as the run destination, then in the project settings → *Signing & Capabilities* choose your personal team (a free Apple ID works).

## What's inside (mapped to the notebook)

| Notebook idea | Where it lives |
|---|---|
| Home page: habits with streaks | Home tab → Habits card; shows 3, "Show all" expands the rest in place (v1.1) |
| Mood emoji row + "(why?)" | Home tab → Mood card (Delighted / Happy / Neutral / Sad / Gloomy) |
| "What happened?" quick capture, saved on the day | Home tab → bottom card; entries land in the Journal grouped by day with their time (1 PM → "Saw a monkey riding an elephant") |
| Bottom bar: Home, Calendar, Create (+), Journal, Profile | The tab bar; the middle **+** opens the create sheet (v1.1: Calendar replaced Habits) |
| Month calendar with "logs of the day" (v1.1) | Calendar tab → pick a day to see its mood, habits done, and journal entries; days with logs get a dot |
| Journals should be editable (v1.1) | Open any entry → pencil button |
| Profile: name, picture, email, birthday, gender | Onboarding on first launch; editable from the Profile tab |
| Add habits: name, start date | Home tab → **+** on the Habits card (icon picker + 30-day history in the detail view) |
| Journal: title, text, photos, voice recording | Journal tab → compose (up to 4 photos, one voice note) |

## Project layout

```
Aware/
├── AwareApp.swift          — app entry + onboarding/main switch
├── Models/Models.swift     — SwiftData models: profile, habit, journal, mood
├── Theme/Theme.swift       — colors (light/dark), card style, avatar
├── Audio/AudioServices.swift — voice note recorder + player
└── Views/
    ├── MainTabView.swift   — tab bar + create sheet
    ├── HomeView.swift      — expandable habits card, mood card, quick capture
    ├── CalendarView.swift  — month grid + logs of the selected day
    ├── HabitDetail.swift   — habit stats/detail + add-habit form
    ├── JournalView.swift   — day-grouped list, detail, compose/edit form
    ├── MoodFormView.swift  — full mood logging form
    └── ProfileView.swift   — profile, edit form, onboarding
```

Everything is stored locally on the device with SwiftData — no account or server needed.

## Deliberate changes from the notes

- **No password.** There's no server, so storing a password would add risk without adding security. If you later want app privacy, Face ID lock is the right tool; if you want sync/login, that's a backend project.
- **No video attachments yet.** Photos + voice notes are in; video is a good v1.1 item.
- **No home-screen widget yet.** It needs a second Xcode target — easy to add once Xcode is installed. Good candidates: today's habit checklist, or a "what happened?" quick-capture button.

## Ideas for next

- Home-screen widgets (habit streaks, quick capture)
- Reminders/notifications for habits
- Mood history chart
- Face ID app lock
