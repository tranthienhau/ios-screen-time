// ContentView.swift
// ScreenTimeDemo
//
// Tab-based navigation providing access to all Screen Time features.

import SwiftUI

struct ContentView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                DashboardView()
            }

            Tab("Block Apps", systemImage: "nosign") {
                AppBlockingView()
            }

            Tab("Schedule", systemImage: "calendar.badge.clock") {
                ScheduleView()
            }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environment(ScreenTimeService())
}
