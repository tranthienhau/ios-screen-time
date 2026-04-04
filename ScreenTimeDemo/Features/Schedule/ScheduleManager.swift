// ScheduleManager.swift
// ScreenTimeDemo
//
// Manages DeviceActivitySchedule registration with DeviceActivityCenter.
//
// KEY CONCEPTS:
// - DeviceActivityCenter: The system service that monitors time-based schedules.
//   When a registered schedule's interval starts, the system launches your
//   DeviceActivityMonitorExtension and calls intervalDidStart().
// - Each schedule is identified by a DeviceActivityName (a string wrapper).
// - Schedules can optionally include DeviceActivityEvents for usage thresholds.
// - The extension runs in a separate process with limited memory (6MB max).

import Foundation
import DeviceActivity
import FamilyControls
import Observation

/// Manages the creation, modification, and monitoring of focus time schedules.
@Observable
final class ScheduleManager {
    // MARK: - Properties

    /// All user-created schedules.
    private(set) var schedules: [BlockSchedule] = []

    /// The DeviceActivityCenter handles schedule registration with the OS.
    private let activityCenter = DeviceActivityCenter()

    /// Service for applying blocking rules per schedule.
    private let deviceActivityService = DeviceActivityService()

    // MARK: - Schedule CRUD

    /// Add a new schedule and start monitoring it.
    func addSchedule(_ schedule: BlockSchedule, selection: FamilyActivitySelection) {
        schedules.append(schedule)

        if schedule.isEnabled {
            startMonitoring(schedule, selection: selection)
        }
    }

    /// Update an existing schedule.
    func updateSchedule(_ schedule: BlockSchedule, selection: FamilyActivitySelection) {
        // Stop monitoring the old schedule
        stopMonitoring(schedule)

        // Update in array
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        }

        // Restart monitoring if enabled
        if schedule.isEnabled {
            startMonitoring(schedule, selection: selection)
        }
    }

    /// Remove a schedule and stop its monitoring.
    func removeSchedule(_ schedule: BlockSchedule) {
        stopMonitoring(schedule)
        schedules.removeAll { $0.id == schedule.id }
    }

    /// Toggle a schedule on or off.
    func toggleSchedule(
        _ schedule: BlockSchedule,
        enabled: Bool,
        selection: FamilyActivitySelection
    ) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }

        schedules[index].isEnabled = enabled

        if enabled {
            startMonitoring(schedules[index], selection: selection)
        } else {
            stopMonitoring(schedules[index])
        }
    }

    // MARK: - Monitoring

    /// Register a schedule with DeviceActivityCenter for system monitoring.
    /// When the schedule's time window begins, the DeviceActivityMonitor
    /// extension receives an intervalDidStart callback.
    private func startMonitoring(_ schedule: BlockSchedule, selection: FamilyActivitySelection) {
        do {
            try deviceActivityService.startMonitoring(
                schedule: schedule,
                selection: selection
            )
        } catch {
            print("Failed to start monitoring schedule '\(schedule.name)': \(error)")
        }
    }

    /// Unregister a schedule from DeviceActivityCenter.
    private func stopMonitoring(_ schedule: BlockSchedule) {
        deviceActivityService.stopMonitoring(schedule: schedule)
    }

    // MARK: - Query

    /// Get all currently monitored activity names from the system.
    var monitoredActivityNames: [DeviceActivityName] {
        Array(activityCenter.activities)
    }

    /// Check if a specific schedule is currently being monitored.
    func isMonitored(_ schedule: BlockSchedule) -> Bool {
        activityCenter.activities.contains(schedule.activityName)
    }

    // MARK: - Bulk Operations

    /// Stop all schedule monitoring.
    func stopAll() {
        activityCenter.stopMonitoring()
        for index in schedules.indices {
            schedules[index].isEnabled = false
        }
    }

    /// Create a predefined "Work Focus" schedule (9am - 5pm, weekdays).
    static func createWorkFocusPreset() -> BlockSchedule {
        BlockSchedule(
            name: "Work Focus",
            startHour: 9,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
            isEnabled: false,
            repeatsDaily: true
        )
    }

    /// Create a predefined "Bedtime" schedule (10pm - 7am).
    static func createBedtimePreset() -> BlockSchedule {
        BlockSchedule(
            name: "Bedtime",
            startHour: 22,
            startMinute: 0,
            endHour: 7,
            endMinute: 0,
            isEnabled: false,
            repeatsDaily: true
        )
    }

    /// Create a predefined "Study Time" schedule (2pm - 6pm).
    static func createStudyPreset() -> BlockSchedule {
        BlockSchedule(
            name: "Study Time",
            startHour: 14,
            startMinute: 0,
            endHour: 18,
            endMinute: 0,
            isEnabled: false,
            repeatsDaily: true
        )
    }
}
