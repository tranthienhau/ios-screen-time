# iOS Screen Time API Demo

A proof-of-concept iOS app demonstrating Apple's Screen Time framework, including Family Controls, ManagedSettings, DeviceActivity monitoring, and Shield customization.

## What This Demonstrates

- **Family Controls Authorization** - Requesting and managing Screen Time API permissions
- **FamilyActivityPicker** - System-provided UI for selecting apps and categories to restrict
- **ManagedSettingsStore** - Applying shield (block) rules to selected applications
- **DeviceActivityMonitor** - Schedule-based monitoring that triggers blocking at specific times
- **ShieldConfiguration** - Custom block screen UI when a restricted app is opened
- **ShieldAction** - Handling user interactions with the block screen buttons
- **App Usage Reports** - Displaying screen time statistics and per-app breakdowns
- **Scheduled Blocking** - Focus time profiles (work, bedtime, study) with automatic app restriction

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Apple Developer Program membership
- **Family Controls entitlement** - must be requested from Apple at:
  https://developer.apple.com/contact/request/family-controls-distribution

## Architecture

```
ios-screen-time/
|
|-- ScreenTimeDemo/                     # Main app target
|   |-- App/
|   |   |-- ScreenTimeDemoApp.swift     # App entry, authorization flow
|   |   |-- ContentView.swift           # Tab-based navigation
|   |
|   |-- Features/
|   |   |-- Dashboard/
|   |   |   |-- DashboardView.swift     # Usage stats, screen time summary
|   |   |   |-- UsageReportView.swift   # Detailed per-app/category breakdown
|   |   |
|   |   |-- AppBlocking/
|   |   |   |-- AppBlockingView.swift   # FamilyActivityPicker integration
|   |   |   |-- BlockedAppsManager.swift # Persistence via App Groups
|   |   |
|   |   |-- Schedule/
|   |   |   |-- ScheduleView.swift      # Create/manage focus schedules
|   |   |   |-- ScheduleManager.swift   # DeviceActivityCenter integration
|   |   |
|   |   |-- Shield/
|   |       |-- ShieldInfo.swift        # Shield customization docs
|   |
|   |-- Services/
|   |   |-- ScreenTimeService.swift     # Core service: auth, ManagedSettingsStore
|   |   |-- DeviceActivityService.swift # Schedule monitoring management
|   |   |-- UsageReportService.swift    # Report configuration and filters
|   |
|   |-- Models/
|       |-- BlockSchedule.swift         # Schedule data model
|       |-- UsageSummary.swift          # Usage statistics models
|
|-- DeviceActivityMonitorExtension/     # Extension target
|   |-- DeviceActivityMonitorExtension.swift  # Interval start/end handlers
|
|-- ShieldConfigurationExtension/       # Extension target
|   |-- ShieldConfigurationExtension.swift    # Custom block screen UI
|
|-- ShieldActionExtension/              # Extension target
    |-- ShieldActionExtension.swift           # Block screen button handlers
```

## Key Frameworks

| Framework | Purpose |
|-----------|---------|
| `FamilyControls` | Authorization, FamilyActivityPicker, FamilyActivitySelection |
| `ManagedSettings` | ManagedSettingsStore for applying app shields/restrictions |
| `ManagedSettingsUI` | ShieldConfigurationDataSource, ShieldActionDelegate |
| `DeviceActivity` | DeviceActivityCenter, DeviceActivitySchedule, DeviceActivityMonitor |

## How to Set Up in Xcode

### 1. Create the Xcode Project

1. Open Xcode, create a new iOS App project (SwiftUI, Swift).
2. Set the deployment target to iOS 16.0.
3. Add source files from `ScreenTimeDemo/` to the main target.

### 2. Add Extension Targets

For each extension, go to File > New > Target:

- **Device Activity Monitor Extension** - Add files from `DeviceActivityMonitorExtension/`
- **Shield Configuration Extension** - Add files from `ShieldConfigurationExtension/`
- **Shield Action Extension** - Add files from `ShieldActionExtension/`

### 3. Configure Capabilities

For the **main app target**:
- Signing & Capabilities > + Capability > Family Controls
- Signing & Capabilities > + Capability > App Groups
  - Add group: `group.com.yourcompany.screentimedemo`

For **each extension target**:
- Signing & Capabilities > + Capability > Family Controls
- Signing & Capabilities > + Capability > App Groups
  - Add the same group: `group.com.yourcompany.screentimedemo`

### 4. Request the Entitlement

The Family Controls capability requires approval from Apple:
1. Go to https://developer.apple.com/contact/request/family-controls-distribution
2. Submit a request describing your app's use case.
3. Apple will grant the entitlement to your provisioning profile.

For development/testing, the entitlement works automatically on devices
enrolled in your development team.

### 5. Info.plist for Extensions

Each extension needs the correct `NSExtensionPointIdentifier`:

- DeviceActivityMonitor: `com.apple.deviceactivity.monitor`
- ShieldConfiguration: `com.apple.deviceactivity.shield-configuration`
- ShieldAction: `com.apple.deviceactivity.shield-action`

Xcode sets these automatically when creating extension targets via the template.

## How It Works

### Authorization Flow
The app requests Family Controls authorization on launch. On a personal device (non-child), the user approves directly. On a child device, a parent/guardian must approve.

### App Blocking
Users select apps via FamilyActivityPicker, which returns opaque tokens (not bundle IDs, for privacy). These tokens are passed to ManagedSettingsStore to apply shields. When a shielded app is opened, iOS shows the custom block screen.

### Scheduled Blocking
Users create focus schedules (e.g., "Work Focus" 9am-5pm). The app registers these with DeviceActivityCenter. When the interval starts, the DeviceActivityMonitor extension activates blocking. When it ends, blocking is removed. This works even when the app is closed.

### Shield Customization
The ShieldConfigurationExtension provides custom UI for the block screen (title, subtitle, icon, colors, button labels). The ShieldActionExtension handles button taps, with support for temporary deferrals.

### Data Sharing
The main app and extensions share data via App Groups (shared UserDefaults). The FamilyActivitySelection is encoded and stored in the shared container so extensions can read which apps to block.

## Privacy Design

Apple's Screen Time API is privacy-first by design:
- App tokens are opaque (you cannot extract bundle IDs or app names).
- Usage data is rendered via system-provided DeviceActivityReport views, not raw data.
- The FamilyActivityPicker is a system UI; your app never sees the full app list.
- Shield extensions run in sandboxed processes with 6MB memory limits.

## License

MIT - This is a proof-of-concept for demonstration purposes.
