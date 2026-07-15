import SwiftUI
import LocalAuthentication
import UIKit

struct SettingsView: View {
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @State private var canUseAppLock = true
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section {
                Toggle("Require Face ID / passcode", isOn: $appLockEnabled)
                    .disabled(!canUseAppLock)
            } header: {
                Text("Privacy")
            } footer: {
                Text(canUseAppLock
                     ? "Aware will ask for Face ID or your passcode every time it opens."
                     : "Set a passcode on this device to use app lock.")
            }

            Section {
                NavigationLink {
                    MoodHistoryView()
                } label: {
                    Label("Mood history", systemImage: "chart.xyaxis.line")
                }
            } header: {
                Text("Insights")
            }

            Section {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Notification settings", systemImage: "bell.badge")
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Daily reminders are set per habit — open a habit from the home screen and turn on its reminder.")
            }

            Section("About") {
                LabeledContent("Version", value: "1.2")
                LabeledContent("Tagline", value: "Be aware with yourself")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var error: NSError?
            canUseAppLock = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        }
        .onChange(of: appLockEnabled) { _, enabled in
            if enabled {
                confirmEnable()
            }
        }
    }

    /// Verify Face ID / passcode once before trusting the lock, so the user
    /// can't lock themselves out with a setting that never authenticates.
    private func confirmEnable() {
        Task {
            let context = LAContext()
            let confirmed = (try? await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Confirm Face ID to turn on app lock."
            )) == true
            if !confirmed {
                appLockEnabled = false
            }
        }
    }
}
