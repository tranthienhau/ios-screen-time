// ScheduleView.swift
// ScreenTimeDemo
//
// Interface for creating and managing focus time schedules.
// Each schedule defines a time window during which selected apps are blocked.

import SwiftUI
import FamilyControls

struct ScheduleView: View {
    @Environment(ScreenTimeService.self) private var screenTimeService

    @State private var scheduleManager = ScheduleManager()
    @State private var showingAddSchedule = false
    @State private var editingSchedule: BlockSchedule?

    var body: some View {
        NavigationStack {
            Group {
                if scheduleManager.schedules.isEmpty {
                    emptyStateView
                } else {
                    scheduleListView
                }
            }
            .navigationTitle("Focus Schedules")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSchedule = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSchedule) {
                ScheduleEditorView(
                    scheduleManager: scheduleManager,
                    screenTimeService: screenTimeService
                )
            }
            .sheet(item: $editingSchedule) { schedule in
                ScheduleEditorView(
                    scheduleManager: scheduleManager,
                    screenTimeService: screenTimeService,
                    existingSchedule: schedule
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Schedules", systemImage: "calendar.badge.clock")
        } description: {
            Text("Create a focus schedule to automatically block distracting apps during specific times.")
        } actions: {
            Button("Add Schedule") {
                showingAddSchedule = true
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Schedule List

    private var scheduleListView: some View {
        List {
            ForEach(scheduleManager.schedules) { schedule in
                ScheduleRowView(
                    schedule: schedule,
                    onToggle: { isEnabled in
                        scheduleManager.toggleSchedule(
                            schedule,
                            enabled: isEnabled,
                            selection: screenTimeService.activitySelection
                        )
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    editingSchedule = schedule
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let schedule = scheduleManager.schedules[index]
                    scheduleManager.removeSchedule(schedule)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("About Schedules", systemImage: "info.circle")
                        .font(.subheadline.bold())

                    Text("Schedules use DeviceActivityMonitor to automatically enable app blocking during the defined time windows. The monitor runs as a system extension, so blocking works even when the app is closed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Schedule Row

struct ScheduleRowView: View {
    let schedule: BlockSchedule
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.headline)

                Text(schedule.timeRangeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    if schedule.repeatsDaily {
                        Label("Daily", systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Schedule Editor

struct ScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    var scheduleManager: ScheduleManager
    var screenTimeService: ScreenTimeService
    var existingSchedule: BlockSchedule?

    @State private var name: String = "Focus Time"
    @State private var startTime = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    )!
    @State private var endTime = Calendar.current.date(
        from: DateComponents(hour: 17, minute: 0)
    )!
    @State private var repeatsDaily = true
    @State private var showingPicker = false
    @State private var scheduleSelection = FamilyActivitySelection()

    var isEditing: Bool { existingSchedule != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Schedule Details") {
                    TextField("Name", text: $name)

                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End Time",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )

                    Toggle("Repeat Daily", isOn: $repeatsDaily)
                }

                Section("Apps to Block") {
                    Button {
                        showingPicker = true
                    } label: {
                        HStack {
                            Text("Select Apps")
                            Spacer()
                            Text("\(scheduleSelection.applicationTokens.count) apps")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .familyActivityPicker(
                        isPresented: $showingPicker,
                        selection: $scheduleSelection
                    )

                    Text("You can select different apps for each schedule. For example, block social media during work hours and games during study time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(isEditing ? "Update Schedule" : "Create Schedule") {
                        saveSchedule()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }

                if isEditing {
                    Section {
                        Button("Delete Schedule", role: .destructive) {
                            if let schedule = existingSchedule {
                                scheduleManager.removeSchedule(schedule)
                            }
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let existing = existingSchedule {
                    name = existing.name
                    startTime = Calendar.current.date(
                        from: DateComponents(hour: existing.startHour, minute: existing.startMinute)
                    ) ?? startTime
                    endTime = Calendar.current.date(
                        from: DateComponents(hour: existing.endHour, minute: existing.endMinute)
                    ) ?? endTime
                    repeatsDaily = existing.repeatsDaily
                }
            }
        }
    }

    private func saveSchedule() {
        let startComponents = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        let endComponents = Calendar.current.dateComponents([.hour, .minute], from: endTime)

        let schedule = BlockSchedule(
            id: existingSchedule?.id ?? UUID(),
            name: name,
            startHour: startComponents.hour ?? 9,
            startMinute: startComponents.minute ?? 0,
            endHour: endComponents.hour ?? 17,
            endMinute: endComponents.minute ?? 0,
            isEnabled: true,
            repeatsDaily: repeatsDaily
        )

        if isEditing {
            scheduleManager.updateSchedule(schedule, selection: screenTimeService.activitySelection)
        } else {
            scheduleManager.addSchedule(schedule, selection: screenTimeService.activitySelection)
        }
    }
}

#Preview {
    ScheduleView()
        .environment(ScreenTimeService())
}
