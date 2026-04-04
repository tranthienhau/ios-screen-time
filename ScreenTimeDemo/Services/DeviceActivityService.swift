// DeviceActivityService.swift
// ScreenTimeDemo
//
// Manages DeviceActivityCenter schedules for monitoring app usage windows.
//
// KEY CONCEPTS:
// - DeviceActivityCenter: Registers time-based monitoring schedules.
//   When a schedule's interval starts or ends, the system launches your
//   DeviceActivityMonitor app extension to handle the event.
// - DeviceActivitySchedule: Defines a recurring time window (e.g., 9am-5pm daily).
// - DeviceActivityName: Unique identifier for each monitoring schedule.
// - DeviceActivityEvent: Optional per-app thresholds within a schedule
//   (e.g., warn after 30 min of social media use).

import Foundation
import DeviceActivity
import FamilyControls
import Observation

/// Service for registering and managing device activity monitoring schedules.
@Observable
final class DeviceActivityService {
    // MARK: - Properties

    /// Active schedules being monitored.
    private(set) var activeSchedules: [BlockSchedule] = []

    /// The DeviceActivityCenter manages schedule registration with the system.
    private let center = DeviceActivityCenter()

    // MARK: - Schedule Management

    /// Start monitoring a schedule. When the schedule's time window begins,
    /// the DeviceActivityMonitor extension receives an `intervalDidStart` callback.
    /// When it ends, `intervalDidEnd` is called.
    ///
    /// - Parameters:
    ///   - schedule: The BlockSchedule to activate.
    ///   - selection: The FamilyActivitySelection of apps to monitor/block.
    func startMonitoring(
        schedule: BlockSchedule,
        selection: FamilyActivitySelection
    ) throws {
        let deviceActivitySchedule = schedule.toDeviceActivitySchedule()

        // Events allow per-app usage thresholds within the schedule window.
        // For example, you can trigger a warning after 30 minutes of a specific app.
        let events = createEvents(for: selection)

        // Register the schedule with the system.
        // The DeviceActivityMonitor extension handles the callbacks.
        try center.startMonitoring(
            schedule.activityName,
            during: deviceActivitySchedule,
            events: events
        )

        if !activeSchedules.contains(where: { $0.id == schedule.id }) {
            activeSchedules.append(schedule)
        }
    }

    /// Stop monitoring a specific schedule.
    func stopMonitoring(schedule: BlockSchedule) {
        center.stopMonitoring([schedule.activityName])
        activeSchedules.removeAll { $0.id == schedule.id }
    }

    /// Stop all active monitoring.
    func stopAllMonitoring() {
        center.stopMonitoring()
        activeSchedules.removeAll()
    }

    // MARK: - Events

    /// Create DeviceActivityEvents for usage threshold warnings.
    /// Events fire when a monitored app reaches a specified usage duration
    /// within the schedule's time window.
    private func createEvents(
        for selection: FamilyActivitySelection
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        // Create a 30-minute usage warning for the selected apps.
        // When any selected app accumulates 30 minutes of usage within the
        // monitored interval, the extension receives an `eventDidReachThreshold` callback.
        let warningThreshold = DateComponents(minute: 30)

        if !selection.applicationTokens.isEmpty {
            let eventName = DeviceActivityEvent.Name("usageWarning")
            let event = DeviceActivityEvent(
                applications: selection.applicationTokens,
                categories: selection.categoryTokens,
                threshold: warningThreshold
            )
            events[eventName] = event
        }

        // You could add more events, e.g., a 1-hour hard block:
        // let hardBlockThreshold = DateComponents(hour: 1)
        // events[DeviceActivityEvent.Name("hardBlock")] = DeviceActivityEvent(...)

        return events
    }

    // MARK: - Query

    /// Get all activity names currently being monitored.
    var monitoredActivities: [DeviceActivityName] {
        // DeviceActivityCenter.activities returns the set of currently monitored names.
        Array(center.activities)
    }
}
