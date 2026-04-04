// DashboardView.swift
// ScreenTimeDemo
//
// Main dashboard showing screen time summary, usage statistics,
// and quick access to blocking controls.

import SwiftUI
import DeviceActivity

struct DashboardView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    @State private var reportService = UsageReportService()
    @State private var showingDetailedReport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    timeRangePicker

                    // Screen Time Summary Card
                    screenTimeSummaryCard

                    // Quick Stats Row
                    quickStatsRow

                    // Category Breakdown
                    categoryBreakdownSection

                    // Top Apps
                    topAppsSection

                    // Blocking Status
                    blockingStatusCard
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingDetailedReport) {
                UsageReportView()
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("Time Range", selection: $reportService.reportTimeRange) {
            ForEach(UsageReportService.ReportTimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Screen Time Summary

    private var screenTimeSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Screen Time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formatDuration(reportService.currentSummary.totalScreenTime))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: "iphone")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            // Simple bar chart showing usage distribution
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(reportService.currentSummary.categoryUsages) { category in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForCategory(category.categoryName))
                            .frame(
                                width: max(
                                    4,
                                    geometry.size.width * category.percentage(
                                        of: reportService.currentSummary.totalScreenTime
                                    ) / 100
                                )
                            )
                    }
                }
                .frame(height: 12)
            }
            .frame(height: 12)

            Button("View Detailed Report") {
                showingDetailedReport = true
            }
            .font(.subheadline)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Pickups",
                value: "\(reportService.currentSummary.pickupCount)",
                icon: "hand.tap.fill",
                color: .orange
            )

            StatCard(
                title: "Notifications",
                value: "\(reportService.currentSummary.notificationCount)",
                icon: "bell.fill",
                color: .red
            )

            StatCard(
                title: "Apps Used",
                value: "\(reportService.currentSummary.appUsages.count)",
                icon: "square.grid.2x2.fill",
                color: .purple
            )
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)

            ForEach(reportService.currentSummary.categoryUsages) { category in
                HStack {
                    Circle()
                        .fill(colorForCategory(category.categoryName))
                        .frame(width: 12, height: 12)

                    Text(category.categoryName)
                        .font(.subheadline)

                    Spacer()

                    Text(category.formattedDuration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(category.percentage(of: reportService.currentSummary.totalScreenTime)))%")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Apps

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Used Apps")
                .font(.headline)

            ForEach(Array(reportService.currentSummary.appUsages.prefix(5).enumerated()), id: \.element.id) { index, app in
                HStack {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForCategory(app.category).opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: iconForCategory(app.category))
                                .foregroundStyle(colorForCategory(app.category))
                        }

                    VStack(alignment: .leading) {
                        Text(app.appName)
                            .font(.subheadline)
                        Text(app.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(app.formattedDuration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Blocking Status

    private var blockingStatusCard: some View {
        HStack {
            Image(systemName: screenTimeService.isBlockingEnabled ? "lock.fill" : "lock.open.fill")
                .font(.title2)
                .foregroundStyle(screenTimeService.isBlockingEnabled ? .red : .green)

            VStack(alignment: .leading) {
                Text(screenTimeService.isBlockingEnabled ? "Blocking Active" : "No Active Blocks")
                    .font(.subheadline.bold())
                if screenTimeService.isBlockingEnabled {
                    Text("\(screenTimeService.blockedAppCount) apps, \(screenTimeService.blockedCategoryCount) categories blocked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if screenTimeService.isBlockingEnabled {
                Button("Disable") {
                    screenTimeService.disableBlocking()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func colorForCategory(_ name: String) -> Color {
        switch name {
        case "Productivity": return .blue
        case "Social": return .pink
        case "Entertainment": return .orange
        case "Communication": return .green
        case "Games": return .purple
        case "Education": return .cyan
        default: return .gray
        }
    }

    private func iconForCategory(_ name: String) -> String {
        switch name {
        case "Productivity": return "briefcase.fill"
        case "Social": return "person.2.fill"
        case "Entertainment": return "play.circle.fill"
        case "Communication": return "message.fill"
        case "Games": return "gamecontroller.fill"
        case "Education": return "book.fill"
        default: return "app.fill"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environment(ScreenTimeService())
}
