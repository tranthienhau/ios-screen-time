// UsageReportService.swift
// ScreenTimeDemo
//
// Fetches and processes device activity reports for usage statistics.
//
// KEY CONCEPTS:
// - DeviceActivityReport: A SwiftUI view that renders usage data from the system.
//   Unlike most APIs, Screen Time reports are rendered via a special SwiftUI view
//   context, not fetched as raw data. This is a privacy-preserving design.
// - DeviceActivityFilter: Specifies which apps/categories/time ranges to include.
// - The report data is rendered by a DeviceActivityReportExtension (app extension).
//
// NOTE: Direct access to raw usage data (app names, bundle IDs, durations) is
// intentionally limited by Apple for privacy. The DeviceActivityReport view
// is the primary way to display usage data to the user.

import Foundation
import DeviceActivity
import ManagedSettings
import Observation

/// Service for managing usage report configurations and sample data.
@Observable
final class UsageReportService {
    // MARK: - Properties

    /// The selected time range for reports.
    var reportTimeRange: ReportTimeRange = .today

    /// Sample usage data for UI development.
    /// In production, real data comes through DeviceActivityReport views.
    private(set) var currentSummary: UsageSummary = .sample

    // MARK: - Report Time Ranges

    enum ReportTimeRange: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "This Week"

        var id: String { rawValue }

        /// Date interval for the selected time range.
        var dateInterval: DateInterval {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                return DateInterval(start: start, end: now)

            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
                let start = calendar.startOfDay(for: yesterday)
                let end = calendar.startOfDay(for: now)
                return DateInterval(start: start, end: end)

            case .thisWeek:
                let weekStart = calendar.dateComponents(
                    [.calendar, .yearForWeekOfYear, .weekOfYear],
                    from: now
                )
                let start = calendar.date(from: weekStart)!
                return DateInterval(start: start, end: now)
            }
        }
    }

    // MARK: - Filter Configuration

    /// Create a DeviceActivityFilter for the current time range.
    /// Filters specify which data to include in DeviceActivityReport views.
    func createFilter(
        for applications: Set<ApplicationToken> = [],
        categories: Set<ActivityCategoryToken> = []
    ) -> DeviceActivityFilter {
        let dateInterval = reportTimeRange.dateInterval

        // DeviceActivityFilter.Segment determines the granularity:
        // .daily groups by day, .hourly groups by hour.
        return DeviceActivityFilter(
            segment: .daily(
                during: dateInterval
            ),
            users: .all,
            devices: .init([.iPhone]),
            applications: applications.isEmpty ? nil : applications,
            categories: categories.isEmpty ? nil : categories
        )
    }

    // MARK: - Context for Report Extension

    /// The DeviceActivityReport scene requires a "context" that your
    /// DeviceActivityReportExtension uses to determine what to render.
    /// In a full implementation, you would create a report extension target.
    static let totalActivityContext = DeviceActivityReport.Context("TotalActivity")
    static let topAppsContext = DeviceActivityReport.Context("TopApps")
    static let categoryBreakdownContext = DeviceActivityReport.Context("CategoryBreakdown")
}
