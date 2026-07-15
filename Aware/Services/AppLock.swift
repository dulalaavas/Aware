import SwiftUI
import LocalAuthentication

/// Locks the app behind Face ID / Touch ID / passcode when enabled in Settings.
@MainActor
final class AppLockController: ObservableObject {
    @Published var isLocked = false
    private var isAuthenticating = false

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "appLockEnabled")
    }

    func lockIfNeeded() {
        if Self.isEnabled {
            isLocked = true
        }
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Device has no passcode set — there is nothing to lock with.
            isLocked = false
            return
        }
        let reason = "Unlock Aware to see your habits and journal."
        if (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) == true {
            isLocked = false
        }
    }
}

struct LockScreenView: View {
    @ObservedObject var appLock: AppLockController

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.appAccentSoft)
                        .frame(width: 96, height: 96)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.appAccent)
                }
                .accessibilityHidden(true)

                Text("Aware is locked")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Color.appInk)

                Button {
                    Task { await appLock.unlock() }
                } label: {
                    Label("Unlock", systemImage: "faceid")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
