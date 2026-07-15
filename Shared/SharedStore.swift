import Foundation
import SwiftData

/// The SwiftData store shared between the app and its widgets via an App Group.
enum SharedStore {
    static let appGroupID = "group.com.aavash.aware"

    static let schema = Schema([
        UserProfile.self,
        Habit.self,
        HabitCompletion.self,
        JournalEntry.self,
        MoodEntry.self
    ])

    static let container: ModelContainer = makeContainer()

    private static func makeContainer() -> ModelContainer {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = groupURL.appendingPathComponent("Aware.store")
            migrateDefaultStoreIfNeeded(to: storeURL)
            let configuration = ModelConfiguration(url: storeURL)
            if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
                return container
            }
        }
        // Fallback when the App Group isn't available (e.g. missing entitlement):
        // keep the app working with the default local store.
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create the Aware data store: \(error)")
        }
    }

    /// One-time move of data written before the App Group existed.
    private static func migrateDefaultStoreIfNeeded(to storeURL: URL) {
        let fileManager = FileManager.default
        let oldBase = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        guard !fileManager.fileExists(atPath: storeURL.path),
              fileManager.fileExists(atPath: oldBase.path) else { return }
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: oldBase.path + suffix)
            let destination = URL(fileURLWithPath: storeURL.path + suffix)
            if fileManager.fileExists(atPath: source.path) {
                try? fileManager.copyItem(at: source, to: destination)
            }
        }
    }
}
