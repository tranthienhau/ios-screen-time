// UsageReportView.swift
// ScreenTimeDemo
//
// Detailed usage breakdown showing per-app and per-category statistics.
//
// NOTE ON DeviceActivityReport:
// In a production app, you would use DeviceActivityReport (a SwiftUI view)
// to render real usage data. This requires a DeviceActivityReportExtension
// target in your Xcode project. The system passes usage data to the extension,
// which renders it in a privacy-preserving way (the main app never sees raw data).
//
// Example of using DeviceActivityReport in production:
//
//   DeviceActivityReport(
//       UsageReportService.totalActivityContext,
//       filter: reportService.createFilter()
//   )
//
// For this POC, we display sample data to demonstrate the UI patterns.

import SwiftUI
import DeviceActivity

struct UsageReportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var reportService = UsageReportService()
    @State private var selectedTab: ReportTab = .apps

    enum ReportTab: String, CaseIterable {
        case apps = "Apps"
        case categories = "Categories"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Time range selector
                Picker("Time Range", selection: $reportService.reportTimeRange) {
                    ForEach(UsageReportService.ReportTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    ForEach(ReportTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Content
                ScrollView {
                    switch selectedTab {
                    case .apps:
                        appListView
                    case .categories:
                        categoryListView
                    }
                }
            }
            .navigationTitle("Usage Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - App List

    private var appListView: some View {
        LazyVStack(spacing: 0) {
            // Total header
            HStack {
                Text("Total Screen Time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDuration(reportService.currentSummary.totalScreenTime))
                    .font(.subheadline.bold())
            }
            .padding()

            Divider()

            // App rows
            ForEach(reportService.currentSummary.appUsages) { app in
                AppUsageRow(
                    app: app,
                    totalTime: reportService.currentSummary.totalScreenTime
                )
                Divider()
                    .padding(.leading, 60)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Category List

    private var categoryListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(reportService.currentSummary.categoryUsages) { category in
                CategoryUsageCard(
                    category: category,
                    totalTime: reportService.currentSummary.totalScreenTime
                )
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - App Usage Row

struct AppUsageRow: View {
    let app: AppUsageEntry
    let totalTime: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "app.fill")
                        .foregroundStyle(.blue)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.body)
                Text(app.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(app.formattedDuration)
                    .font(.subheadline)

                // Usage bar
                GeometryReader { geo in
                    let percentage = totalTime > 0 ? app.duration / totalTime : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue.opacity(0.3))
                        .frame(width: geo.size.width * percentage)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(width: 80, height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Category Usage Card

struct CategoryUsageCard: View {
    let category: CategoryUsageEntry
    let totalTime: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.categoryName)
                    .font(.headline)
                Spacer()
                Text(category.formattedDuration)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(
                            width: geo.size.width * category.percentage(of: totalTime) / 100
                        )
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(category.appCount) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(category.percentage(of: totalTime)))% of total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    UsageReportView()
}
