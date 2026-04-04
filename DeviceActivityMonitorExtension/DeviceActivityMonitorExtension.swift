// DeviceActivityMonitorExtension.swift
// DeviceActivityMonitorExtension
//
// This extension handles schedule-based events from DeviceActivityCenter.
// It runs as a separate process launched by the system when schedule
// intervals start/end or when usage thresholds are reached.
//
// SETUP IN XCODE:
// 1. File > New > Target > Device Activity Monitor Extension
// 2. Add "Family Controls" capability to this extension target.
// 3. Add "App Groups" capability (same group as main app).
// 4. The extension's Info.plist must include NSExtension with:
//    - NSExtensionPointIdentifier: com.apple.deviceactivity.monitor
//    - NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).DeviceActivityMonitorExtension
//
// MEMORY LIMIT: This extension has a strict 6MB memory limit.
// Keep operations lightweight - no heavy frameworks or large data structures.

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// Subclass of DeviceActivityMonitor that responds to schedule events.
/// The system calls these methods when the monitored intervals start/end.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // MARK: - Shared State

    /// Access shared App Group storage for reading the blocked apps selection.
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.yourcompany.screentimedemo")
    }

    /// A named ManagedSettingsStore for schedule-based blocking.
    /// Using a named store keeps schedule blocks separate from manual blocks.
    private let store = ManagedSettingsStore(named: .focusTime)

    // MARK: - Interval Callbacks

    /// Called when a monitored schedule's time window begins.
    /// This is where you apply blocking rules (shields) for the schedule period.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the persisted selection from App Groups.
        // The main app saves the FamilyActivitySelection here.
        guard let data = sharedDefaults?.data(forKey: "blockedAppsSelection") else {
            return
        }

        do {
            let selection = try PropertyListDecoder().decode(
                FamilyActivitySelection.self,
                from: data
            )

            // Apply shields to the selected apps and categories.
            // These shields remain active until intervalDidEnd is called.
            let applications = selection.applicationTokens
            let categories = selection.categoryTokens

            store.shield.applications = applications.isEmpty ? nil : applications
            store.shield.applicationCategories = categories.isEmpty
                ? nil
                : ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)

        } catch {
            // In a production app, log this error to a shared file or analytics.
            // The extension has no UI, so print statements go to system logs.
        }
    }

    /// Called when a monitored schedule's time window ends.
    /// Remove blocking rules so the user can access their apps again.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Clear all shields from the schedule's managed settings store.
        store.clearAllSettings()
    }

    // MARK: - Event Callbacks

    /// Called when a DeviceActivityEvent threshold is reached.
    /// For example, if you set a 30-minute warning event, this fires
    /// after 30 minutes of cumulative usage within the interval.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // You can respond to usage thresholds here.
        // Common actions:
        // - Apply stricter shields (block more apps).
        // - Send a local notification (via shared app group + notification extension).
        // - Log the event for the main app to display later.

        if event == DeviceActivityEvent.Name("usageWarning") {
            // Example: The user has used selected apps for 30 minutes.
            // You could escalate to a full block:
            // store.shield.applications = ... (expand the block set)

            // Or persist a flag for the main app to show a warning:
            sharedDefaults?.set(true, forKey: "usageWarningTriggered")
            sharedDefaults?.set(Date(), forKey: "usageWarningTimestamp")
        }
    }

    /// Called when a specific app's usage reaches the event threshold
    /// while the interval is active.
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        // This is called shortly before the interval starts (if configured).
        // Useful for pre-loading data or preparing the blocking state.
    }

    /// Called shortly before the interval ends.
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)

        // Useful for cleanup or sending a "focus time ending soon" notification.
    }
}
