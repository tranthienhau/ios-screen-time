// UsageSummary.swift
// ScreenTimeDemo
//
// Models for representing app usage data retrieved from the Screen Time API.

import Foundation

/// Summary of device usage for display in the dashboard.
struct UsageSummary: Identifiable {
    let id = UUID()
    let date: Date
    let totalScreenTime: TimeInterval
    let appUsages: [AppUsageEntry]
    let categoryUsages: [CategoryUsageEntry]
    let pickupCount: Int
    let notificationCount: Int
}

/// Usage data for a single application.
struct AppUsageEntry: Identifiable {
    let id = UUID()
    let appName: String
    let bundleIdentifier: String?
    let duration: TimeInterval
    let category: String

    /// Formatted duration string (e.g., "2h 15m").
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

/// Usage data grouped by app category.
struct CategoryUsageEntry: Identifiable {
    let id = UUID()
    let categoryName: String
    let duration: TimeInterval
    let appCount: Int

    /// Formatted duration string.
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Percentage of total screen time for chart displays.
    func percentage(of total: TimeInterval) -> Double {
        guard total > 0 else { return 0 }
        return (duration / total) * 100
    }
}

// MARK: - Sample Data for Previews

extension UsageSummary {
    /// Sample data for SwiftUI previews and development.
    static let sample = UsageSummary(
        date: Date(),
        totalScreenTime: 14400, // 4 hours
        appUsages: [
            AppUsageEntry(appName: "Safari", bundleIdentifier: "com.apple.mobilesafari", duration: 3600, category: "Productivity"),
            AppUsageEntry(appName: "Instagram", bundleIdentifier: "com.burbn.instagram", duration: 2700, category: "Social"),
            AppUsageEntry(appName: "YouTube", bundleIdentifier: "com.google.ios.youtube", duration: 2400, category: "Entertainment"),
            AppUsageEntry(appName: "Messages", bundleIdentifier: "com.apple.MobileSMS", duration: 1800, category: "Communication"),
            AppUsageEntry(appName: "Slack", bundleIdentifier: "com.tinyspeck.chatlyio", duration: 1500, category: "Productivity"),
            AppUsageEntry(appName: "Twitter", bundleIdentifier: "com.atebits.Tweetie2", duration: 1200, category: "Social"),
            AppUsageEntry(appName: "Mail", bundleIdentifier: "com.apple.mobilemail", duration: 900, category: "Productivity"),
            AppUsageEntry(appName: "Spotify", bundleIdentifier: "com.spotify.client", duration: 300, category: "Entertainment"),
        ],
        categoryUsages: [
            CategoryUsageEntry(categoryName: "Productivity", duration: 6000, appCount: 3),
            CategoryUsageEntry(categoryName: "Social", duration: 3900, appCount: 2),
            CategoryUsageEntry(categoryName: "Entertainment", duration: 2700, appCount: 2),
            CategoryUsageEntry(categoryName: "Communication", duration: 1800, appCount: 1),
        ],
        pickupCount: 45,
        notificationCount: 120
    )
}
