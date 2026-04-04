// BlockedAppsManager.swift
// ScreenTimeDemo
//
// Manages persistence and synchronization of blocked app selections
// across the main app and its extensions via App Groups.
//
// IMPORTANT: App extensions (DeviceActivityMonitor, ShieldConfiguration, ShieldAction)
// run in separate processes. To share data between the main app and extensions,
// you must use App Groups (shared UserDefaults or shared container directory).
//
// SETUP IN XCODE:
// 1. Add "App Groups" capability to the main app target AND all extension targets.
// 2. Use the same group identifier (e.g., "group.com.yourcompany.screentimedemo").
// 3. Access shared data via UserDefaults(suiteName: "group.com.yourcompany.screentimedemo").

import Foundation
import FamilyControls
import ManagedSettings
import Observation

/// Manages the persistence of blocked app selections using App Groups for
/// cross-process sharing between the main app and extensions.
@Observable
final class BlockedAppsManager {
    // MARK: - Constants

    /// App Group identifier for sharing data with extensions.
    /// Must match the App Group configured in Xcode for all targets.
    static let appGroupIdentifier = "group.com.yourcompany.screentimedemo"

    /// UserDefaults keys for persisted data.
    private enum Keys {
        static let selectionData = "blockedAppsSelection"
        static let isBlockingEnabled = "isBlockingEnabled"
        static let lastUpdated = "selectionLastUpdated"
    }

    // MARK: - Properties

    /// The current app/category selection.
    var selection = FamilyActivitySelection()

    /// Whether blocking is currently enabled.
    var isBlockingEnabled: Bool = false

    /// Shared UserDefaults for the App Group.
    private let sharedDefaults: UserDefaults?

    // MARK: - Initialization

    init() {
        sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
        loadPersistedState()
    }

    // MARK: - Persistence

    /// Save the current selection to shared App Group storage.
    /// Extensions can read this to know which apps should be blocked.
    func saveSelection() {
        guard let defaults = sharedDefaults else { return }

        // FamilyActivitySelection conforms to Codable, but the tokens are opaque.
        // We encode and store the selection data.
        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: Keys.selectionData)
            defaults.set(isBlockingEnabled, forKey: Keys.isBlockingEnabled)
            defaults.set(Date(), forKey: Keys.lastUpdated)
        } catch {
            print("Failed to save selection: \(error)")
        }
    }

    /// Load the persisted selection from App Group storage.
    func loadPersistedState() {
        guard let defaults = sharedDefaults else { return }

        isBlockingEnabled = defaults.bool(forKey: Keys.isBlockingEnabled)

        if let data = defaults.data(forKey: Keys.selectionData) {
            do {
                selection = try PropertyListDecoder().decode(
                    FamilyActivitySelection.self,
                    from: data
                )
            } catch {
                print("Failed to load selection: \(error)")
            }
        }
    }

    /// Get the token sets for use in ManagedSettingsStore or extensions.
    var applicationTokens: Set<ApplicationToken> {
        selection.applicationTokens
    }

    var categoryTokens: Set<ActivityCategoryToken> {
        selection.categoryTokens
    }

    /// Check if a specific application token is in the blocked set.
    func isBlocked(_ token: ApplicationToken) -> Bool {
        selection.applicationTokens.contains(token)
    }

    /// Clear all persisted state.
    func clearAll() {
        selection = FamilyActivitySelection()
        isBlockingEnabled = false

        guard let defaults = sharedDefaults else { return }
        defaults.removeObject(forKey: Keys.selectionData)
        defaults.removeObject(forKey: Keys.isBlockingEnabled)
        defaults.removeObject(forKey: Keys.lastUpdated)
    }
}
