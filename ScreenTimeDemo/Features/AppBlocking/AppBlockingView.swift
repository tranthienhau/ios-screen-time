// AppBlockingView.swift
// ScreenTimeDemo
//
// Allows users to select apps and categories to block using FamilyActivityPicker.
//
// KEY CONCEPTS:
// - FamilyActivityPicker: A system-provided SwiftUI view that shows the user's
//   installed apps grouped by category. The user selects which apps/categories
//   to restrict. The picker returns opaque tokens (not bundle IDs) for privacy.
// - FamilyActivitySelection: The result of the picker, containing sets of
//   ApplicationToken and ActivityCategoryToken.
// - After selection, tokens are passed to ManagedSettingsStore to apply shields.

import SwiftUI
import FamilyControls

struct AppBlockingView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    @State private var showingPicker = false
    @State private var showingConfirmation = false

    var body: some View {
        @Bindable var service = screenTimeService

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    statusCard

                    // App Selection
                    appSelectionSection(service: service)

                    // Blocking Toggle
                    blockingToggleSection(service: service)

                    // Info Section
                    infoSection

                    // Reset Button
                    if screenTimeService.blockedAppCount > 0 || screenTimeService.isBlockingEnabled {
                        resetButton
                    }
                }
                .padding()
            }
            .navigationTitle("Block Apps")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(screenTimeService.isBlockingEnabled ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: screenTimeService.isBlockingEnabled ? "nosign" : "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(screenTimeService.isBlockingEnabled ? .red : .green)
            }

            Text(screenTimeService.isBlockingEnabled ? "Blocking Active" : "No Blocks Active")
                .font(.title3.bold())

            if screenTimeService.blockedAppCount > 0 {
                Text("\(screenTimeService.blockedAppCount) apps and \(screenTimeService.blockedCategoryCount) categories selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - App Selection

    private func appSelectionSection(service: Bindable<ScreenTimeService>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Select Apps to Block", systemImage: "square.grid.2x2")
                .font(.headline)

            Text("Use the Family Activity Picker to choose which apps and categories to restrict. Selected apps will show a shield screen when opened.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // FamilyActivityPicker is a system-provided view.
            // It binds to a FamilyActivitySelection and lets the user
            // pick apps and categories from their installed apps.
            //
            // The picker can be presented inline or as a sheet.
            // Here we show it as a button that opens a sheet.
            Button {
                showingPicker = true
            } label: {
                Label("Choose Apps & Categories", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // Present FamilyActivityPicker as a sheet.
            // The $service.activitySelection binding is updated when
            // the user confirms their selection.
            .familyActivityPicker(
                isPresented: $showingPicker,
                selection: service.activitySelection
            )
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Blocking Toggle

    private func blockingToggleSection(service: Bindable<ScreenTimeService>) -> some View {
        VStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { screenTimeService.isBlockingEnabled },
                set: { newValue in
                    if newValue {
                        screenTimeService.enableBlocking()
                    } else {
                        screenTimeService.disableBlocking()
                    }
                }
            )) {
                VStack(alignment: .leading) {
                    Text("Enable Blocking")
                        .font(.headline)
                    Text("Shield selected apps when opened")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(screenTimeService.blockedAppCount == 0 && screenTimeService.blockedCategoryCount == 0)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "info.circle")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                InfoRow(number: 1, text: "Select apps or categories using the picker above")
                InfoRow(number: 2, text: "Enable blocking to activate shields on selected apps")
                InfoRow(number: 3, text: "When a blocked app is opened, a shield screen appears")
                InfoRow(number: 4, text: "The shield can be customized via ShieldConfigurationExtension")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button(role: .destructive) {
            showingConfirmation = true
        } label: {
            Label("Reset All Blocks", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .confirmationDialog("Reset all blocks?", isPresented: $showingConfirmation) {
            Button("Reset", role: .destructive) {
                screenTimeService.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all app selections and disable blocking.")
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Circle())

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AppBlockingView()
        .environment(ScreenTimeService())
}
