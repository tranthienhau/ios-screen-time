// ScreenTimeDemoApp.swift
// ScreenTimeDemo
//
// Demonstrates Screen Time API / Family Controls framework on iOS 16+.
//
// ENTITLEMENTS REQUIRED:
// - com.apple.developer.family-controls (requires Apple Developer Program approval)
//
// CAPABILITIES TO ENABLE IN XCODE:
// 1. Family Controls
// 2. App Groups (shared container for extensions)
//
// The Family Controls entitlement must be requested via:
// https://developer.apple.com/contact/request/family-controls-distribution

import SwiftUI
import FamilyControls

@main
struct ScreenTimeDemoApp: App {
    // MARK: - State

    @State private var screenTimeService = ScreenTimeService()
    @State private var isAuthorized = false
    @State private var authError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthorized {
                    ContentView()
                        .environment(screenTimeService)
                } else {
                    AuthorizationView(
                        isAuthorized: $isAuthorized,
                        authError: $authError,
                        onAuthorize: requestAuthorization
                    )
                }
            }
            .task {
                await checkExistingAuthorization()
            }
        }
    }

    // MARK: - Authorization

    /// Check if the user has already granted Family Controls authorization.
    private func checkExistingAuthorization() async {
        // AuthorizationCenter.shared.authorizationStatus is available on iOS 16+
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved {
            isAuthorized = true
        }
    }

    /// Request Family Controls authorization from the user.
    /// On a child device, this triggers a parent/guardian approval prompt.
    /// On an individual device (non-child), the user approves directly.
    private func requestAuthorization() {
        Task {
            do {
                // .individual is for personal device usage (not parental control).
                // Use .child for parental control scenarios.
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    isAuthorized = true
                    authError = nil
                }
            } catch {
                await MainActor.run {
                    authError = "Authorization failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Authorization View

/// Shown when the app has not yet been authorized for Family Controls.
struct AuthorizationView: View {
    @Binding var isAuthorized: Bool
    @Binding var authError: String?
    let onAuthorize: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Screen Time Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("This app uses the Screen Time API to monitor and manage app usage. Authorization is required to access Family Controls.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: onAuthorize) {
                Label("Authorize Screen Time", systemImage: "lock.open.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            if let error = authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Text("Requires iOS 16+ and Family Controls entitlement")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
    }
}
