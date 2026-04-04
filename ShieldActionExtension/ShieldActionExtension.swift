// ShieldActionExtension.swift
// ShieldActionExtension
//
// Handles user interactions with the shield (block screen) buttons.
// When the user taps the primary or secondary button on a shield,
// this extension determines what happens next.
//
// SETUP IN XCODE:
// 1. File > New > Target > Shield Action Extension
// 2. Add "Family Controls" capability to this extension target.
// 3. Add "App Groups" capability (same group as main app).
// 4. The extension's Info.plist must include NSExtension with:
//    - NSExtensionPointIdentifier: com.apple.deviceactivity.shield-action
//    - NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ShieldActionExtension
//
// SHIELD ACTIONS:
// - .close: Dismiss the shield and return to the home screen.
// - .defer: Allow the app to open temporarily (use with caution).
//
// MEMORY LIMIT: 6MB. Keep this extension lightweight.

import ManagedSettings
import ManagedSettingsUI
import Foundation

/// Subclass of ShieldActionDelegate that handles shield button taps.
class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - Shared State

    /// Access shared App Group storage for logging shield interactions.
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.yourcompany.screentimedemo")
    }

    // MARK: - Application Shield Actions

    /// Called when the user taps the primary button on an app's shield.
    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Primary button: Close the shield and return to home screen.
            // Log the interaction for the main app's analytics.
            logShieldInteraction(action: "primaryDismiss", type: "application")
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Secondary button: "Need More Time?" - you could implement
            // a grace period here by deferring the shield.
            //
            // .defer temporarily allows the app to open.
            // .close dismisses back to home screen.
            //
            // For this demo, we log and close. In production, you might
            // show a time picker or grant a 5-minute extension.
            logShieldInteraction(action: "secondaryDismiss", type: "application")
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Web Domain Shield Actions

    /// Called when the user taps a button on a web domain's shield.
    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            logShieldInteraction(action: "primaryDismiss", type: "webDomain")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logShieldInteraction(action: "secondaryDismiss", type: "webDomain")
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Category Shield Actions

    /// Called when the user taps a button on a category-blocked app's shield.
    override func handle(
        action: ShieldAction,
        for application: Application,
        in category: ActivityCategory,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            logShieldInteraction(action: "primaryDismiss", type: "appInCategory")
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Example: Grant a temporary deferral for category-blocked apps.
            // In production, you might check if the user has remaining deferrals
            // and either .defer or .close accordingly.
            let deferralsUsed = sharedDefaults?.integer(forKey: "deferralsUsedToday") ?? 0
            let maxDeferrals = 3

            if deferralsUsed < maxDeferrals {
                sharedDefaults?.set(deferralsUsed + 1, forKey: "deferralsUsedToday")
                logShieldInteraction(action: "deferral", type: "appInCategory")
                completionHandler(.defer)
            } else {
                logShieldInteraction(action: "deferralDenied", type: "appInCategory")
                completionHandler(.close)
            }

        @unknown default:
            completionHandler(.close)
        }
    }

    /// Called when the user taps a button on a category-blocked web domain's shield.
    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        in category: ActivityCategory,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            logShieldInteraction(action: "primaryDismiss", type: "webInCategory")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logShieldInteraction(action: "secondaryDismiss", type: "webInCategory")
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Logging

    /// Log shield interactions to shared storage for the main app to read.
    private func logShieldInteraction(action: String, type: String) {
        guard let defaults = sharedDefaults else { return }

        // Increment total shield interactions counter.
        let count = defaults.integer(forKey: "shieldInteractionCount")
        defaults.set(count + 1, forKey: "shieldInteractionCount")

        // Store the last interaction details.
        defaults.set(action, forKey: "lastShieldAction")
        defaults.set(type, forKey: "lastShieldType")
        defaults.set(Date().timeIntervalSince1970, forKey: "lastShieldTimestamp")
    }
}
