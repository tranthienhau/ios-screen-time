// BlockSchedule.swift
// ScreenTimeDemo
//
// Model representing a scheduled app-blocking period (e.g., focus time).

import Foundation
import FamilyControls
import DeviceActivity

/// A user-defined schedule for blocking selected apps during specific time windows.
struct BlockSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool
    var repeatsDaily: Bool

    // FamilyActivitySelection is not Codable, so we track it separately.
    // In a production app, you would persist token data via App Groups.

    init(
        id: UUID = UUID(),
        name: String = "Focus Time",
        startHour: Int = 9,
        startMinute: Int = 0,
        endHour: Int = 17,
        endMinute: Int = 0,
        isEnabled: Bool = true,
        repeatsDaily: Bool = true
    ) {
        self.id = id
        self.name = name
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.isEnabled = isEnabled
        self.repeatsDaily = repeatsDaily
    }

    /// Convert to a DeviceActivitySchedule for use with DeviceActivityCenter.
    /// DeviceActivitySchedule defines when monitoring should be active.
    func toDeviceActivitySchedule() -> DeviceActivitySchedule {
        let start = DateComponents(hour: startHour, minute: startMinute)
        let end = DateComponents(hour: endHour, minute: endMinute)

        return DeviceActivitySchedule(
            intervalStart: start,
            intervalEnd: end,
            repeats: repeatsDaily
        )
    }

    /// A DeviceActivityName derived from this schedule's ID.
    /// Used to register/unregister monitoring with DeviceActivityCenter.
    var activityName: DeviceActivityName {
        DeviceActivityName(rawValue: id.uuidString)
    }

    /// Human-readable time range string.
    var timeRangeDescription: String {
        let startStr = String(format: "%02d:%02d", startHour, startMinute)
        let endStr = String(format: "%02d:%02d", endHour, endMinute)
        return "\(startStr) - \(endStr)"
    }
}
