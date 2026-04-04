// ShieldInfo.swift
// ScreenTimeDemo
//
// Documentation and configuration for ShieldConfiguration customization.
//
// SHIELD OVERVIEW:
// When a user tries to open a blocked (shielded) app, iOS displays a
// "shield" overlay instead of the app. The shield appearance is controlled
// by a ShieldConfigurationExtension, and the button actions are handled
// by a ShieldActionExtension.
//
// ARCHITECTURE:
// 1. Main app sets shield rules via ManagedSettingsStore.
// 2. User taps a blocked app.
// 3. iOS shows the shield overlay.
// 4. ShieldConfigurationExtension provides the UI content (title, body, icon, colors).
// 5. ShieldActionExtension handles button taps (primary and secondary actions).
//
// IMPORTANT NOTES:
// - Shield extensions run in a separate process with very limited memory (6MB).
// - They cannot access the main app's data directly (use App Groups).
// - ShieldConfigurationExtension must return quickly (no long network calls).
// - The shield UI is limited to the ShieldConfiguration structure:
//   - backgroundBlurStyle
//   - backgroundColor
//   - icon (SF Symbol or custom)
//   - title (styled text)
//   - subtitle (styled text)
//   - primaryButtonLabel (styled text)
//   - primaryButtonBackgroundColor
//   - secondaryButtonLabel (styled text)

import Foundation

/// Reference information about shield customization capabilities.
/// This struct exists as documentation; the actual implementation
/// lives in the ShieldConfigurationExtension and ShieldActionExtension targets.
enum ShieldInfo {
    /// Describes the customizable parts of a shield screen.
    static let customizationGuide = """
    Shield Configuration Options:
    - Background: blur style + tint color
    - Icon: system symbol or custom image (limited size)
    - Title: attributed text with custom font/color
    - Subtitle: attributed text with custom font/color
    - Primary button: label text + background color
    - Secondary button: optional, label text only

    Shield Action Options:
    - Primary action: .close (dismiss shield) or .defer (let user in temporarily)
    - Secondary action: same options

    The shield is displayed per-app, so you can customize it based on
    which specific application or category triggered it.
    """

    /// App Group identifier (must match across all targets).
    static let appGroupIdentifier = BlockedAppsManager.appGroupIdentifier
}
