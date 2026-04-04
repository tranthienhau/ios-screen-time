// ScreenTimeService.swift
// ScreenTimeDemo
//
// Central service wrapping AuthorizationCenter, ManagedSettingsStore,
// and FamilyActivitySelection for the Screen Time API.
//
// KEY CONCEPTS:
// - AuthorizationCenter: Requests user permission for Family Controls.
// - ManagedSettingsStore: Applies restrictions (blocking apps, shielding).
//   Each store is identified by a name. You can have multiple named stores
//   for different blocking profiles (e.g., "focus", "bedtime").
// - FamilyActivitySelection: Holds the user's selected apps/categories
//   from FamilyActivityPicker. Contains opaque tokens, not bundle IDs.

import Foundation
import FamilyControls
import ManagedSettings
import Observation

/// Observable service managing Screen Time authorization and app blocking state.
@Observable
final class ScreenTimeService {
    // MARK: - Properties

    /// The user's current app/category selection from FamilyActivityPicker.
    /// This selection contains opaque Application and Category tokens.
    var activitySelection = FamilyActivitySelection() {
        didSet {
            // When the selection changes, update the managed settings store
            // to reflect the new set of blocked apps.
            applyBlockingRules()
        }
    }

    /// Whether app blocking is currently active.
    var isBlockingEnabled: Bool = false

    /// The number of currently blocked apps (approximate, since tokens are opaque).
    var blockedAppCount: Int {
        activitySelection.applicationTokens.count
    }

    /// The number of currently blocked categories.
    var blockedCategoryCount: Int {
        activitySelection.categoryTokens.count
    }

    // MARK: - Private

    /// The ManagedSettingsStore applies restrictions to the device.
    /// Using a named store allows multiple independent blocking profiles.
    /// The ".default" name is a convenience for single-store usage.
    private let store = ManagedSettingsStore()

    // MARK: - App Blocking

    /// Apply the current FamilyActivitySelection as shield (block) rules.
    /// Shielded apps show a "blocked" overlay when the user tries to open them.
    func applyBlockingRules() {
        guard isBlockingEnabled else {
            clearBlockingRules()
            return
        }

        let applications = activitySelection.applicationTokens
        let categories = activitySelection.categoryTokens

        // ShieldSettings controls what happens when a blocked app is launched.
        // Setting applications/categories here will show a shield overlay.
        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)

        // You can also restrict web domains:
        // store.shield.webDomains = ...
        // store.shield.webDomainCategories = ...
    }

    /// Remove all blocking rules from the managed settings store.
    func clearBlockingRules() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    /// Enable blocking with the current selection.
    func enableBlocking() {
        isBlockingEnabled = true
        applyBlockingRules()
    }

    /// Disable all blocking.
    func disableBlocking() {
        isBlockingEnabled = false
        clearBlockingRules()
    }

    /// Reset everything: clear selection and disable blocking.
    func reset() {
        activitySelection = FamilyActivitySelection()
        isBlockingEnabled = false
        clearBlockingRules()
    }

    // MARK: - Named Stores

    /// Apply blocking rules to a named store (useful for schedule-based blocking).
    /// Each schedule can have its own ManagedSettingsStore with independent rules.
    func applyBlockingRules(
        for storeName: ManagedSettingsStore.Name,
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>
    ) {
        let namedStore = ManagedSettingsStore(named: storeName)
        namedStore.shield.applications = applications.isEmpty ? nil : applications
        namedStore.shield.applicationCategories = categories.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)
    }

    /// Clear blocking rules from a named store.
    func clearBlockingRules(for storeName: ManagedSettingsStore.Name) {
        let namedStore = ManagedSettingsStore(named: storeName)
        namedStore.clearAllSettings()
    }
}

// MARK: - ManagedSettingsStore.Name Extension

extension ManagedSettingsStore.Name {
    /// Store name for focus-time blocking.
    static let focusTime = Self("focusTime")

    /// Store name for bedtime blocking.
    static let bedtime = Self("bedtime")
}
