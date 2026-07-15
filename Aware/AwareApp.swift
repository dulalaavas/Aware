import SwiftUI
import SwiftData
import WidgetKit

/// Cross-view signals, e.g. the quick-capture deep link from the widget.
final class AppRouter: ObservableObject {
    @Published var capturePending = false
}

@main
struct AwareApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router = AppRouter()
    @StateObject private var appLock = AppLockController()

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                if appLock.isLocked {
                    LockScreenView(appLock: appLock)
                        .transition(.opacity)
                }
            }
            .environmentObject(router)
            .tint(.appAccent)
            .onOpenURL { url in
                if url.host == "capture" {
                    router.capturePending = true
                }
            }
            .task {
                appLock.lockIfNeeded()
                await appLock.unlock()
            }
        }
        .modelContainer(SharedStore.container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                appLock.lockIfNeeded()
                WidgetCenter.shared.reloadAllTimelines()
            case .active:
                Task { await appLock.unlock() }
            default:
                break
            }
        }
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
