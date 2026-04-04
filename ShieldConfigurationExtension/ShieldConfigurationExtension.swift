// ShieldConfigurationExtension.swift
// ShieldConfigurationExtension
//
// Provides custom appearance for the shield (block screen) shown when
// a user attempts to open a restricted app.
//
// SETUP IN XCODE:
// 1. File > New > Target > Shield Configuration Extension
// 2. Add "Family Controls" capability to this extension target.
// 3. Add "App Groups" capability (same group as main app).
// 4. The extension's Info.plist must include NSExtension with:
//    - NSExtensionPointIdentifier: com.apple.deviceactivity.shield-configuration
//    - NSExtensionPrincipalClass: $(PRODUCT_MODULE_NAME).ShieldConfigurationExtension
//
// MEMORY LIMIT: 6MB. Keep this extension lightweight.
//
// HOW IT WORKS:
// When a shielded app is launched, iOS calls this extension to get the
// ShieldConfiguration. The configuration defines the visual appearance
// of the block screen (title, subtitle, icon, colors, button labels).
// The extension receives the application or category token that triggered
// the shield, so you can customize the appearance per-app.

import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Subclass of ShieldConfigurationDataSource that provides custom shield appearances.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Application Shield

    /// Called when a specific blocked application is opened.
    /// Return a ShieldConfiguration describing how the block screen should look.
    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        // `application` contains an opaque token. You cannot get the bundle ID
        // or app name directly. However, you can customize based on the
        // application's localizedDisplayName (available in some contexts).

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "hourglass.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "App Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is restricted during your focus time. Stay focused and try again later.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Need More Time?",
                color: UIColor.systemBlue
            )
        )
    }

    // MARK: - Application in Category Shield

    /// Called when an app is blocked because its category is restricted.
    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        // You can customize based on the category.
        // For example, social media apps could show a different message
        // than entertainment apps.

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "nosign"),
            title: ShieldConfiguration.Label(
                text: "Category Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Apps in this category are restricted during your focus time.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemRed,
            secondaryButtonLabel: nil
        )
    }

    // MARK: - Web Domain Shield

    /// Called when a blocked web domain is accessed (via Safari/WebKit).
    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "globe.badge.chevron.backward"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website is restricted during your focus time.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemOrange,
            secondaryButtonLabel: nil
        )
    }

    // MARK: - Web Domain in Category Shield

    /// Called when a web domain is blocked because its category is restricted.
    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "globe.badge.chevron.backward"),
            title: ShieldConfiguration.Label(
                text: "Website Category Blocked",
                color: UIColor.secondaryLabel
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Websites in this category are restricted.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor.systemOrange,
            secondaryButtonLabel: nil
        )
    }
}
