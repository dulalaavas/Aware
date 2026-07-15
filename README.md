# Aware

**Be aware with yourself.**

Aware is an iOS app for noticing your own days: the habits you keep, the moods you move through, and the small moments that would otherwise slip away. Everything stays on your device — no account, no server, no feed.

It started as a handwritten sketch in a notebook, and the app still follows that page.

## What Aware does

### 🏠 Home
Your whole day on one screen:
- **Habits** — your daily habits with 🔥 streak counts and a one-tap circle to mark today done. Shows three, expands in place to show them all.
- **Mood** — five faces (Delighted, Happy, Neutral, Sad, Gloomy). Pick one, say *why*, done. One mood per day; you can change your mind.
- **What happened?** — a quick-capture box for moments as they happen. Each capture is stamped with its time and saved to that day's journal (*1 PM — "Saw a monkey riding an elephant"*).

### 📓 Journal
Day-by-day entries with a title, your thoughts, up to 4 photos, and a recorded voice note. Quick notes from Home land here too. Every entry can be edited or deleted later.

### 🗓 Calendar
A month view of your life in the app. Days with logs get a dot; tap any day to see the mood you felt, the habits you completed, and everything you wrote.

### 📱 Home-screen widgets
- **Habit streaks** — small (your top streak) or medium (up to three habits). Tap the circle to mark a habit done *right from the home screen*.
- **Quick capture** — one tap opens Aware with the "What happened?" field ready to type.

### 🔔 Habit reminders
Each habit can have a daily reminder at a time you choose — a gentle nudge to keep the streak alive. Set it when creating a habit or from the habit's page.

### 📈 Mood history
A 30-day mood line, an all-time breakdown of how often you feel each way, and your most common mood. Reachable from the mood card on Home or from Settings.

### 🔒 Face ID lock
Turn on app lock in Settings and Aware asks for Face ID (or your passcode) every time it opens. Your journal is yours.

### 👤 Profile & Settings
A local profile — name, photo, email, birthday, gender — with your totals (habits, entries, moods). The gear opens Settings: app lock, notification settings, mood history, and about.

## Design

Calm minimalism: warm ivory background, deep sage green, a soft ember flame for streaks, serif display headings. Full light **and** dark mode. SF Symbols for interface icons; emoji where they belong — as moods and habit icons you pick yourself.

## Tech

| | |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Data | SwiftData, stored in an App Group container shared with the widgets |
| Widgets | WidgetKit + App Intents (interactive check-off) |
| Charts | Swift Charts |
| Reminders | UserNotifications |
| App lock | LocalAuthentication (Face ID / Touch ID / passcode) |
| Audio | AVFoundation voice notes |

No third-party dependencies.

## Running it

1. Open `Aware.xcodeproj` in **Xcode 16 or newer**.
2. Pick an iPhone simulator and press **⌘R**.
3. To try the widgets: long-press the simulator/device home screen → **+** → search "Aware".

For a real iPhone, select your device and set your team under *Signing & Capabilities* for **both** targets (Aware and AwareWidgetsExtension). The App Group `group.com.aavash.aware` lets the widgets read your data.

## Project layout

```
Aware/
├── Aware/                    — the app
│   ├── AwareApp.swift        — entry point, deep links, app lock, widget refresh
│   ├── Services/             — notifications, Face ID lock
│   ├── Audio/                — voice note recorder + player
│   └── Views/                — Home, Calendar, Journal, Habits, Mood, Profile, Settings
├── Shared/                   — compiled into app AND widgets
│   ├── Models.swift          — SwiftData models (profile, habit, journal, mood)
│   ├── SharedStore.swift     — App Group data container
│   └── Theme.swift           — colors, cards, avatar
└── AwareWidgets/             — widget extension (streaks + quick capture)
```

## Roadmap ideas

- Video attachments in journal entries
- Weekly reflection summaries
- Lock screen widgets
- iCloud sync

---

*Built from a paper sketch. ✏️*
